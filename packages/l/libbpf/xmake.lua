package("libbpf")
    set_homepage("https://github.com/libbpf/libbpf")
    set_description("Automated upstream mirror for libbpf standalone build.")

    set_urls("https://github.com/libbpf/libbpf/archive/$(version).tar.gz",
             "https://github.com/libbpf/libbpf.git")
    add_versions("latest", "master")
    add_versions("v0.7.0", "2cd2d03f63242c048a896179398c68d2dbefe3d6")
    add_versions("v0.6.1", "56794b31eea0a6245f194b5915e3ed867be144fe")
    add_versions("v0.6.0", "4884bf3dbd08762564de71608da9941b50184f8b")

    add_deps("elfutils", "zlib")

    add_includedirs("include", "include/uapi")

    on_load("android", function (package)
        import("core.tool.toolchain")
        local ndk_sdkver = toolchain.load("ndk", {plat = package:plat(), arch = package:arch()}):config("ndk_sdkver")
        if ndk_sdkver and tonumber(ndk_sdkver) < 23 then
            package:add("deps", "memorymapping")
        end
    end)

    on_install("linux", "android", function (package)
        io.writefile("xmake.lua", [[
            add_rules("mode.debug", "mode.release")
            add_requires("elfutils", "zlib")
            target("bpf")
                set_kind("$(kind)")
                add_packages("elfutils", "zlib")
                add_files("src/*.c")
                add_includedirs("include")
                add_includedirs("include/uapi", { public = true })
                add_headerfiles("src/(*.h)", {prefixdir = "bpf"})
                if is_plat("android") then
                    add_defines("__user=", "__force=", "__poll_t=uint32_t")
                end
        ]])
        local configs = {}
        configs.kind = "static" -- default
        if package:config("shared") then
            configs.kind = "shared"
        elseif package:config("pic") ~= false then
            configs.cxflags = "-fPIC"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("bpf_object__open", {includes = "bpf/libbpf.h"}))
    end)

