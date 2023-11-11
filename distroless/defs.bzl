"Public API re-exports"

load("//distroless/private:cacerts.bzl", _cacerts = "cacerts")
load("//distroless/private:locale.bzl", _locale = "locale")

cacerts = _cacerts
locale = _locale
