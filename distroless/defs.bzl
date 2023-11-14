"Public API re-exports"

load("//distroless/private:cacerts.bzl", _cacerts = "cacerts")
load("//distroless/private:locale.bzl", _locale = "locale")
load("//distroless/private:os_release.bzl", _os_release = "os_release")

cacerts = _cacerts
locale = _locale
os_release = _os_release
