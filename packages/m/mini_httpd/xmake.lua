package("mini_httpd")
    set_homepage("https://acme.com/software/mini_httpd")
    set_description("Small HTTP server")

    add_urls("https://acme.com/software/mini_httpd/mini_httpd-$(version).tar.gz")
    add_versions("1.30", "9c4481802af8dde2e164062185c279e9274525c3af93d014fdc0b80cf30bca6e")

    on_install("linux", function(package)
        local bindir = package:installdir("bin")
        local mandir = package:installdir("man")
        package:addenv("PATH", bindir)

        import("package.tools.make")
        make.make(package, {"CDEFS=-DHAVE_INT64T", "BINDIR=" .. bindir, "MANDIR=" .. mandir, "install"})
    end)

    on_test("linux", function(package)
        os.execv("mini_httpd", { "-V" })
    end)
