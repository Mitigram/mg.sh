#!/usr/bin/env sh

is_abspath() {
  case "$1" in
    /* | ~*) true;;
    *) false;;
  esac
}
