#!/usr/bin/env coffee
# read the .js files
# for now, we only do this for the physical constants

fs = require('fs')

define = (x) -> x

header = ->
    '''
    # CoCalc Examples Documentation File
    # Copyright: CoCalc Authors, 2018
    # This is derived content from the BSD licensed https://github.com/moble/jupyter_boilerplate/

    # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # THIS FILE IS AUTOGENERATED -- DO NOT EDIT BY HAND #
    # # # # # # # # # # # # # # # # # # # # # # # # # # #

    ---
    language: python
    ''' + '\n'

###
this is the main function doing the conversion. it assumes the .js datastructures are read in
by evaluating the string. it might be necessary to redefine "define" (from the one above)

* entry: the root of a tree of entries. read_submenu might be call recursively (only once), too!
* cat0: the main category name (kept upon recursive calls)
* name_prefix: that's the second level, and cat1 upon recursion. see the computation of "subcat"
* cat_prefix: that's named a bit wrong, because this is the additional setup code for a subcategory
* cat_process: function (by default idempotent) for processing the category name (mainly used to make the words shorter)
* sortweight: some categories should be at the top, e.g. related to introduction, etc. just use (-1 to push them at the top, default 0)
* variables: dictionary of variable defaults, which are added like "setup". they're dynamically inserted by the UI component. for testing, just add them to the setup. Care needs to be taken to use language specific syntax (usually, "key = value", though)
* testing: false if it shouldn't be tested
###
read_submenu = (entry, cat0, name_prefix, cat_prefix, cat_process, sortweight, variables, testing) ->
    cat_process ?= (x) -> x
    if name_prefix?
        prefix = "#{name_prefix}"
    else
        prefix = ''
    submenu  = entry['sub-menu']
    cat1     = cat_process(entry['name'])
    output   = []

    if cat1 == 'Example'
        return output

    output.push('---')
    subcat = (x for x in [prefix, cat1] when x?.length > 0).join(' / ')
    output.push("category: ['#{cat0}', '#{subcat}']")
    sw = sortweight?(entry['name'])
    if sw
        output.push("sortweight: #{sw}")
    if cat_prefix?
        # JSON.stringify to sanitize linebreaks
        output.push("setup: #{JSON.stringify(cat_prefix)}")
    if variables?
        output.push("variables: #{JSON.stringify(variables)}")

    for entry in entry['sub-menu']
        # there are weird "---"
        if typeof entry == 'string'
            continue
        # oh yes, sub entries can have subentries ... just skipping them via recursion.
        if entry['sub-menu']?
            output = output.concat(read_submenu(entry, cat0, cat1, cat_prefix, cat_process, sortweight, variables))
        else
            continue if not entry.snippet?  # there are entries where it is only entry["external-link"]
            continue if entry.snippet.join('').trim().length == 0 # ... or some are just empty
            output.push('---')
            #console.log(JSON.stringify(entry))
            output.push("title: |\n  #{entry.name}")
            #console.log(JSON.stringify(entry))
            code = ("  #{x}" for x in entry.snippet).join('\n')
            output.push("code: |\n#{code}")
            if testing == false
                output.push("test: false")
    return output

# This is specific to scipy special functions file
read_scipy_special = ->
    special_js   = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/scipy_special.js', 'utf8')
    constants    = eval(special_js)
    output       = []
    cat_prefix   = '''
                   from scipy import special, integrate, optimize, interpolate
                   from scipy.integrate import odeint
                   '''
    variables =
        n     : 2
        v     : 1.5
        x     : 1.5
        z     : 0.5
        alpha : 0.5
        beta  : 0.5
        nt    : 5

    cat_process = (x) ->
        if x.indexOf('Bessel Functions') >= 0
            return x.replace('Bessel Functions', 'Bessel').trim()
        if x.indexOf('Statistical Functions (see also scipy.stats)') >= 0
            return x.replace('Statistical Functions (see also scipy.stats)', 'Statistics').trim()
        return x

    for entry in constants['sub-menu']
        if entry['sub-menu']?
            name = cat_process(entry['name'])
            if name == 'Statistics'
                vars = Object.assign({}, variables,
                    a    : 0
                    b    : 1
                    k    : 1
                    p    : .75
                    df   : 0
                    dfn  : 1
                    dfd  : 0.5
                    x    : .66
                    std  : 3
                    t    : 1
                    nc   : 2
                    f    : 0.7
                )
            else if name in ['Mathieu and Related Functions', 'Spheroidal Wave Functions']
                vars = Object.assign({}, variables,
                    m : 1
                    q : 2
                    x : 3
                    c : 1.1
                    n : 1
                 )
            else if name in ['Other Special Functions']
                vars = Object.assign({}, variables,
                    n : 4
                    k : 2
                    z : 1.1
                 )
            else if name in ['Information Theory Functions']
                vars = Object.assign({}, variables,
                    x : [-1, 2, 3]
                    y : [1, 0, 1.1]
                    delta : 0.4
                 )
            else
                vars = variables
            output = output.concat(read_submenu(entry, 'SciPy / Special Func', null, cat_prefix, cat_process, undefined, vars))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/scipy_special.yaml', content, 'utf8')

# This is specific to matplotlib file
read_matplotlib = ->
    matplotlib_js  = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/matplotlib.js', 'utf8')
    constants      = eval(matplotlib_js)
    output         = []
    cat_prefix     = '''
                     import numpy as np
                     import matplotlib as mpl
                     import matplotlib.pyplot as plt
                     '''

    for entry in constants['sub-menu']
        if entry['sub-menu']?
            output = output.concat(read_submenu(entry, 'Visualization', 'Matplotlib', cat_prefix, null))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/matplotlib_boilerplate.yaml', content, 'utf8')


# This is specific to the constants file, prints out yaml to stdout
read_constants = ->
    constants_js = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/scipy_constants.js', 'utf8')
    constants    = eval(constants_js)
    output       = []
    cat_prefix   = 'from scipy import constants'

    cat_process = (cat) ->
        return cat
            .replace('Common physical constants', 'Physical')
            .replace('CODATA physical constants', 'CODATA')
            .trim()

    sortweight = (cat) ->
        if cat in ['Mathematical constants', 'Common physical constants']
            return -1
        return null

    for entry in constants['sub-menu']
        if entry['sub-menu']?
            output = output.concat(read_submenu(entry, 'SciPy / Constants', null, cat_prefix, cat_process, sortweight))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/constants.yaml', content, 'utf8')


# Importing regex is disabled. The examples aren't really helpful.
# There is still the "python/python_regex.yaml" file with some examples, though...
## This is specific to the constants file, prints out yaml to stdout
#read_python_regex = ->
#    pyregex_js   = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/python_regex.js', 'utf8')
#    pyregex      = eval(pyregex_js)
#    output       = []
#    cat_prefix   = 'import re'
#
#    for entry in pyregex['sub-menu']
#        if entry['sub-menu']?
#            output = output.concat(read_submenu(entry, 'Regular Expressions', null, cat_prefix))
#
#    content = header()
#    content += output.join('\n')
#
#    fs.writeFileSync('src/python/python_regex.yaml', content, 'utf8')


read_numpy = ->
    numpy_ufuncs_js       = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/numpy_ufuncs.js', 'utf8')
    numpy_ufuncs          = eval(numpy_ufuncs_js)
    numpy_polynomial_js   = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/numpy_polynomial.js', 'utf8')
    numpy_polynomial      = eval(numpy_polynomial_js)
    # redefine define -- in particular, assumptions and functions is defined now
    orig_define = define
    try
        define = (a, b) ->
            return b(null, numpy_ufuncs, numpy_polynomial)
        numpy_js              = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/numpy.js', 'utf8')
        numpy                 = eval(numpy_js)
    finally
        define = orig_define
    output                = []

    make_prefix = (group) ->
        switch group
            when 'Polynomials'
                 '''
                 import numpy as np
                 from numpy.polynomial import Polynomial as P
                 poly = P([1, 2, 3])
                 '''
            when 'Pretty printing'
                 '''
                 import numpy as np
                 import contextlib
                 @contextlib.contextmanager
                 def printoptions(*args, **kwargs):
                     original = np.get_printoptions()
                     np.set_printoptions(*args, **kwargs)
                     yield
                     np.set_printoptions(**original)
                 '''
            else '''
                 import numpy as np
                 '''
    variables =
        n            : 2
        a            : 'np.array([3, 4, -1, 9.81])'
        b            : 'np.array([0, -1, 2, -3])'
        a_min        : 'np.array([-1, -1, 0, 0])'
        a_max        : 'np.array([1, 1, 5, 10])'
        old_array    : 'np.array([3, 4, -1, 9.81])'
        axis1        : 0
        axis2        : 1
        x            : 'np.array([  0, 1, 4.4,  -9])'
        x1           : 'np.array([0.1, 1, 2.2, 3.5])'
        x2           : 'np.array([ -4, 3, 0.2, 1.5])'

    cat_process = (x) ->
        if x == 'NumPy'
            return null
        if x.indexOf('Vectorized (universal) functions') >= 0
            return x.replace('Vectorized (universal) functions', 'UFuncs').trim()
        if x.indexOf('Indexing and testing arrays') >= 0
            return x.replace('Indexing and testing arrays', 'Indexing').trim()
        return x.trim()

    for entry in numpy['sub-menu']
        if entry['sub-menu']?
            #console.log("read_numpy: '#{entry['name']}"', entry)
            cat_prefix = make_prefix(entry['name'])

            testing = undefined
            if entry['name'] == 'File I/O'
                testing = false

            output = output.concat(read_submenu(entry, 'NumPy', null, cat_prefix, cat_process, undefined, variables, testing))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/numpy_boilerplate.yaml', content, 'utf8')


read_sympy = ->
    assumptions_js     = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/sympy_assumptions.js', 'utf8')
    sympy_assumptions  = eval(assumptions_js)
    functions_js       = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/sympy_functions.js', 'utf8')
    sympy_functions    = eval(functions_js)
    # redefine define -- in particular, assumptions and functions is defined now
    orig_define = define
    try
        define = (a, b) ->
            return b(null, sympy_functions, sympy_assumptions)
        sympy_js           = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/sympy.js', 'utf8')
        sympy              = eval(sympy_js)
    finally
        define = orig_define
    output         = []
    cat_prefix     = '''
                     from sympy import *
                     from sympy.abc import a, b, s, t, u, v, w, x, y, z
                     k, m, n = symbols("k, m, n", integer=True)
                     f, g, h = symbols("f, g, h", cls=Function)
                     '''
    variables =
        d: 3

    cat_process = (x) ->
        if x == 'Sympy'
            return null
        return x

    for entry in sympy['sub-menu']
        if entry['sub-menu']?
            output = output.concat(read_submenu(entry, 'Sympy', null, cat_prefix, cat_process, undefined, variables))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/sympy_boilerplate.yaml', content, 'utf8')

read_scipy = ->
    orig_define = define
    try
        define = (a, b) ->
            return b(null, {}, {})
        scipy_js           = fs.readFileSync('tmp/jupyter_boilerplate/snippets_submenus_python/scipy.js', 'utf8')
        scipy              = eval(scipy_js)
    finally
        define = orig_define
    output         = []
    cat_prefix     = '''
                     import numpy as np
                     import scipy
                     from scipy import integrate, optimize, interpolate
                     '''
    cat_process = (x) ->
        if x == 'SciPy'
            return null
        if x.indexOf('Interpolation and smoothing splines') >= 0
            return x.replace('Interpolation and smoothing splines', 'Interpolation').trim()
        if x.indexOf('Optimization and root-finding routines') >= 0
            return x.replace('Optimization and root-finding routines', 'Optimization').trim()
        return x

    for entry in scipy['sub-menu']
        if entry['sub-menu']?
            output = output.concat(read_submenu(entry, 'SciPy', null, cat_prefix, cat_process))

    content = header()
    content += output.join('\n')

    fs.writeFileSync('src/python/scipy_boilerplate.yaml', content, 'utf8')

main = ->
    read_constants()
    read_scipy_special()
    read_matplotlib()
    #read_python_regex()
    # sympy and numpy redefined "define", hence they must come last!
    read_numpy()
    read_sympy()
    read_scipy()

main()