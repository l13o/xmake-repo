package("bats")
    set_homepage("https://bats-core.readthedocs.io")
    set_description("Bash Automated Testing System")

    set_urls("https://github.com/bats-core/bats-core/archive/refs/tags/$(version).tar.gz",
             "https://github.com/bats-core/bats-core.git")
    add_versions("v1.7.0", "ac70c2a153f108b1ac549c2eaa4154dea4a7c1cc421e3352f0ce6ea49435454e")

    on_install("linux", function (package)
        local install = path.absolute("install.sh")
        if install then
            package:addenv("PATH", "bin")
            os.execv(install, { package:installdir() })
        end
    end)

    on_test("linux", function (package)
        os.vrun("bats -v")
    end)