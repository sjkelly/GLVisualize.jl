using GLVisualize, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Colors, GeometryTypes


# From behaviour, we understand that loading GLFW opens the window

function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end


function dropequal(a::Signal)
    is_equal = foldp((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(const_lift(first, is_equal), a.value, a)
end

function eval_visualize(source::AbstractString, _, visualize_screen, edit_screen)
    expr = parse(strip(source), raise=false)
    val = "not found"
    try
        val = eval(Main, expr)
    catch e
        return nothing
    end
    if applicable(visualize, val)
        clear!(visualize_screen.renderlist)
        clear!(edit_screen.renderlist)
        obj     = visualize(val, screen=visualize_screen)

        push!(visualize_screen.renderlist, obj)
    end
    nothing
end

function init_romeo()
    w, renderloop = glscreen()
    sourcecode_area = const_lift(w.area) do x
    	Rectangle(0, 0, div(x.w, 7)*3, x.h)
    end
    visualize_area = const_lift(w.area) do x
        Rectangle(div(x.w,7)*3, 0, div(x.w, 7)*3, x.h)
    end
    search_area = const_lift(visualize_area) do x
        Rectangle(x.x, x.y, x.w, div(x.h,10))
    end
    edit_area = const_lift(w.area) do x
    	Rectangle(div(x.w, 7)*6, 0, div(x.w, 7), x.h)
    end


    sourcecode_screen   = Screen(w, area=sourcecode_area)
    visualize_screen    = Screen(w, area=visualize_area)
    search_screen       = Screen(visualize_screen, area=search_area)
    edit_screen         = Screen(w, area=edit_area)

    w_height = const_lift(getfield, w.area, :h)
    source_offset = const_lift(w_height) do x
        translationmatrix(Vec3f0(30,x-30,0))
    end
    w_height_search = const_lift(getfield, search_screen.area, :h)
    search_offset = const_lift(w_height_search) do x
        translationmatrix(Vec3f0(30,x-30,0))
    end

    sourcecode  = visualize("barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n", model=source_offset, styles=Texture([RGBA{U8}(0.9,1.0,1.,1)]))
    
    barplot     = visualize(Float32[(sin(i/10f0) + cos(j/2f0))/4f0 + 1f0 for i=1:10, j=1:10])
    search      = visualize("barplot\n", model=search_offset, styles=Texture([RGBA{U8}(0.9,1.0,1.,1)]))

    view(barplot, visualize_screen)
    view(search, search_screen)

    background, cursor_robj, text_sig = vizzedit(sourcecode[:glyphs], sourcecode, w.inputs)
    view(background, sourcecode_screen)
    view(sourcecode, sourcecode_screen)
    view(cursor_robj, sourcecode_screen)

    glClearColor(0,0,0,0)

    renderloop()
end

init_romeo()


