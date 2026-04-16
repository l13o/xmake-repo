package("libbpf")
    set_homepage("https://github.com/libbpf/libbpf")
    set_description("Automated upstream mirror for libbpf stand-alone build.")
    set_license("BSD-2-Clause")

    add_urls("https://github.com/libbpf/libbpf/archive/refs/tags/$(version).tar.gz",
             "https://github.com/libbpf/libbpf.git")
    add_versions("v1.7.0", "7ab5feffbf78557f626f2e3e3204788528394494715a30fc2070fcddc2051b7b")
    add_versions("v1.6.3", "989ed3c1a3db8ff0f7c08dd43953c6b9d0c3ac252653a48d566aaedf98bc80ca")
    add_versions("v1.6.2", "16f31349c70764cba8e0fad3725cc9f52f6cf952554326aa0229daaa21ef4fbd")
    add_versions("v0.8.0", "f4480242651a93c101ece320030f6b2b9b437f622f807719c13cb32569a6d65a")
    add_versions("v0.7.0", "5083588ce5a3a620e395ee1e596af77b4ec5771ffc71cff2af49dfee38c06361")
    add_versions("v0.6.1", "ce3a8eb32d85ac48490256597736d8b27e0a5e947a0731613b7aba6b4ae43ac0")
    add_versions("v0.6.0", "c951c231c51a272b737d33d32517525a91467f409745921a4303192f3aef4103")

    add_deps("zlib")

    add_includedirs("include", "include/uapi")

    on_load(function (package)
        if package:version() and package:version():lt("0.5") then
            package:add("deps", "libelf")
        else
            package:add("deps", "elfutils")
        end
    end)

    if on_check then
        on_check("android", function (package)
            local ndk = package:toolchain("ndk")
            local ndk_sdkver = ndk:config("ndk_sdkver")
            if package:version() and package:version():lt("0.5") then
                assert(ndk_sdkver and tonumber(ndk_sdkver) >= 23,
                    "package(libbpf) dep(libelf): need ndk api level >= 23 for android")
            else
                -- elfutils needs api level <= 23
                assert(ndk_sdkver and tonumber(ndk_sdkver) == 23,
                    "package(libbpf) dep(elfutils): need ndk api level == 23 for android")
            end
        end)
    end

    on_install("linux", "android", function (package)
        local libelfname = package:version():lt("0.5") and "libelf" or "elfutils"
        io.writefile("xmake.lua", format([[
            add_rules("mode.debug", "mode.release")
            add_requires("%s", "zlib")
            target("bpf")
                set_kind("$(kind)")
                add_files("src/*.c")
                add_includedirs("include")
                add_includedirs("include/uapi", {public = true})
                add_packages("%s", "zlib")
                add_headerfiles("src/(*.h)", {prefixdir = "bpf"})
                add_headerfiles("include/(uapi/**/*.h)")
                if is_plat("android") then
                    add_defines("__user=", "__force=", "__poll_t=uint32_t")
                end
        ]], libelfname, libelfname))
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

        if package:version():ge("v1.0.0") then
            assert(package:has_cfuncs("libbpf_major_version", {includes = "bpf/libbpf.h"}))
            assert(package:has_cfuncs("libbpf_bpf_prog_type_str", {includes = "bpf/libbpf.h"}))
        end
    end)
