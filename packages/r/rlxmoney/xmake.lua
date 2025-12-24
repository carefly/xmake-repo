package("rlxmoney")
    -- 设置包的基本信息
    set_homepage("https://github.com/carefly/RLXMoney")
    set_description("A comprehensive money management plugin for Minecraft based on LeviLamina")
    set_license("MIT")

    -- 包配置选项
    add_configs("shared", {description = "Use shared library (DLL) instead of static library", default = true, type = "boolean"})
    add_configs("runtime", {description = "Link runtime statically", default = false, type = "boolean"})
    add_configs("debug", {description = "Enable debug symbols", default = false, type = "boolean"})

    -- 下载 URL（必须在 on_source() 中设置）
    on_source("windows", function(package)
        local version_obj = package:version()
        local version = version_obj and version_obj:rawstr() or "1.0.1"
        local config = package:config("shared") and "shared" or "static"
        local arch = package:is_arch("x64") and "x64" or "arm64"
        local debug_suffix = package:config("debug") and "-debug" or ""
        
        -- 构造下载 URL（根据实际发布的文件名格式）
        local urls = {
            string.format("https://github.com/carefly/RLXMoney/releases/download/v%s/sdk-windows-%s-%s%s.zip",
                         version, arch, config, debug_suffix)
        }
        package:set("urls", urls)
    end)

    -- 加载配置
    on_load(function(package)
        -- 根据配置确定包名
        if package:config("shared") then
            package:add("defines", "RLXMONEY_IMPORTS")
            package:set("basename", "rlxmoney")
        else
            package:add("defines", "RLXMONEY_STATIC")
            package:set("basename", "rlxmoney-static")
        end

        -- 添加包含目录
        package:add("includedirs", "include")

        -- 添加库目录和链接库
        package:add("linkdirs", "lib")
        if package:config("shared") then
            package:add("links", "RLXMoney")
        else
            package:add("links", "SDK-static")
        end

        -- 添加依赖
        package:add("deps", "sqlitecpp", "nlohmann_json")

        -- 设置运行时库
        if package:config("runtime") then
            package:set("runtimes", "MT")
        else
            package:set("runtimes", "MD")
        end

        -- 添加编译定义
        package:add("defines", "NOMINMAX", "UNICODE")
        package:add("cxflags", "/EHa", "/utf-8", "/W4")
    end)

    -- 安装函数
    on_install("windows", function(package)
        -- 验证文件哈希（可选）
        -- package:set("sha256", "...")

        -- 解压（xmake 会自动下载）
        package:extract()

        -- 复制头文件到安装目录
        if os.isdir("include") then
            os.cp("include/*", package:installdir("include"))
        else
            raise("include directory not found in package")
        end

        -- 复制库文件到安装目录
        local lib_name = package:config("shared") and "RLXMoney.lib" or "SDK-static.lib"
        
        if os.isfile(lib_name) then
            os.cp(lib_name, package:installdir("lib"))
        else
            raise("library file " .. lib_name .. " not found in package")
        end
    end)