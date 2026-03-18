chuniio_min = static_library(
    'chuniio-min',
    name_prefix : '',
    include_directories : inc,
    implicit_include_directories : false,
    sources : [
        'chuniio/config.c',
        'chuniio/ledoutput.c',
        'chuniio/pipeimpl.c',
        'chuniio/serialimpl.c',
        'util/dprintf.c',
        'util/env.c',
    ],
)

chuniio_proxy = shared_library(
    'chuniio-proxy',
    name_prefix : '',
    include_directories : inc,
    implicit_include_directories : false,
    sources : [ 'chuniio/chuniio-proxy.c' ],
    link_with : [ chuniio_min ],
    dependencies : [ ws2_32_lib ],
)
