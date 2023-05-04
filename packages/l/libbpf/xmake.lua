package("libbpf")
    set_homepage("https://github.com/libbpf/libbpf")
    set_description("Automated upstream mirror for libbpf standalone build.")

    set_urls("https://github.com/libbpf/libbpf/archive/$(version).tar.gz",
             "https://github.com/libbpf/libbpf.git")
    add_versions("v0.8.0", "f4480242651a93c101ece320030f6b2b9b437f622f807719c13cb32569a6d65a")
    add_versions("v0.7.0", "5083588ce5a3a620e395ee1e596af77b4ec5771ffc71cff2af49dfee38c06361")
    add_versions("v0.6.1", "ce3a8eb32d85ac48490256597736d8b27e0a5e947a0731613b7aba6b4ae43ac0")
    add_versions("v0.6.0", "c951c231c51a272b737d33d32517525a91467f409745921a4303192f3aef4103")

    add_deps("libelf", "zlib")

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
            add_requires("libelf", "zlib")
            target("bpf")
                set_kind("$(kind)")
                add_packages("libelf", "zlib")
                add_files("src/*.c")
                add_includedirs("include")
                add_includedirs("include/uapi", { public = true })
                add_headerfiles("src/(*.h)", {prefixdir = "bpf"})
                if is_plat("android") then
                    add_defines("__user=", "__force=", "__poll_t=uint32_t")
                end
        ]])
        local configs = {}
        configs.kind = "static"
        if package:config("shared") then
            configs.kind = "shared"
        elseif package:config("pic") ~= false then
            configs.cxflags = "-fPIC"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("bpf_object__open", {includes = "bpf/libbpf.h"}))

        if package:version():ge("v0.7.0") then
            assert(package:has_cfuncs("bpf_xdp_attach", {includes = "bpf/libbpf.h"}))
            assert(package:has_cfuncs("libbpf_probe_bpf_helper", {includes = "bpf/libbpf.h"}))
        end

        if package:version():ge("v0.8.0") then
            assert(package:has_cfuncs("bpf_map__autocreate", {includes = "bpf/libbpf.h"}))
            assert(package:has_cfuncs("bpf_object__open_subskeleton", {includes = "bpf/libbpf.h"}))
            assert(package:has_cfuncs("libbpf_register_prog_handler", {includes = "bpf/libbpf.h"}))
        end
    end)
