"EXPERIMENTAL! Public API"

load("//apt/private:dpkg_status.bzl", _dpkg_status = "dpkg_status")
load("//apt/private:dpkg_statusd.bzl", _dpkg_statusd = "dpkg_statusd")

dpkg_status = _dpkg_status
dpkg_statusd = _dpkg_statusd
