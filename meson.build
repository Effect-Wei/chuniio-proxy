project('chuniio-proxy', 'c', version: '0.1.0', default_options: ['werror=true'])

add_project_arguments(
    '-DCOBJMACROS',
    '-DWIN32_LEAN_AND_MEAN',
    '-D_WIN32_WINNT=_WIN32_WINNT_WIN7',
    '-DMINGW_HAS_SECURE_API=1',
    language: 'c',
)

cc = meson.get_compiler('c')

if cc.get_id() != 'msvc'
    add_project_arguments(
        '-ffunction-sections',
        '-fdata-sections',
        '-Wno-unused',
        language: 'c',
    )

    add_global_arguments(
        '-Wno-unknown-pragmas',
        language: 'c',
    )

    add_project_link_arguments(
        '-Wl,--enable-stdcall-fixup',
        '-Wl,--exclude-all-symbols',
        '-Wl,--gc-sections',
        '-static-libgcc',
        '-lws2_32',
        language: 'c',
    )
endif

ws2_32_lib = cc.find_library('ws2_32')

inc = include_directories('src')

subdir('src')
