visualize_default(value::Any, style::Style, kw_args=Dict{Symbol, Any}) = error("""There are no defaults for the type $(typeof(value)),
	which either means the implementation is incomplete or not implemented yet.
	Consider defining visualize_default(::$(typeof(value)), ::Style, parameters::Dict{Symbol, Any}) => Dict{Symbol, Any} and
	visualize(::$(typeof(value)), ::Style, parameters::Dict{Symbol, Any}) => RenderObject""")

function visualize_default(
		value::Any, style::Symbol, kw_args::Vector{Any}, 
		defaults=Dict(
		    :model      	  => Signal(eye(Mat4f0)),
		    :light      	  => Signal(Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]),
		    :preferred_camera => :perspective
		)
	)
	parameters_dict 		= Dict{Symbol, Any}(kw_args)
	parameters_calculated 	= visualize_default(value, Style{style}(), parameters_dict)
	merge(defaults, parameters_calculated, parameters_dict)
end

visualize(value::Any, 	  style::Symbol=:default; kw_args...) = visualize(value,  Style{style}(), visualize_default(value, 	      style, kw_args))
visualize(signal::Signal, style::Symbol=:default; kw_args...) = visualize(signal, Style{style}(), visualize_default(signal.value, style, kw_args))
visualize(file::File, 	  style::Symbol=:default; kw_args...) = visualize(FileIO.load(file), style; kw_args...)

visualize(robj::RenderObject) = robj


function view(
		robj::RenderObject, screen=ROOT_SCREEN;
		method 	 = robj.uniforms[:preferred_camera],
		position = Vec3f0(2), lookat=Vec3f0(0)
	)
    if haskey(screen.cameras, method)
        camera = screen.cameras[method]
    elseif method == :perspective
		camera = PerspectiveCamera(screen.inputs, position, lookat)
	elseif method == :fixed_pixel
		camera = DummyCamera(window_size=screen.area)
	elseif method == :orthographic_pixel
		camera = OrthographicPixelCamera(screen.inputs)
	elseif method == :nothing
		return push!(screen.renderlist, robj)
	else
         error("Method $method not a known camera type")
	end
	merge!(robj.uniforms, collect(camera), Dict(
		:resolution => const_lift(Vec2f0, screen.inputs[:framebuffer_size]),
		:fixed_projectionview => get(screen.cameras, :fixed_pixel, DummyCamera(window_size=screen.area)).projectionview
	))
	push!(screen.renderlist, robj)
end

view(robjs::Vector{RenderObject}, screen=ROOT_SCREEN; kw_args...) = for robj in robjs
	view(robj, screen; kw_args...)
end
view(c::Composable, screen=ROOT_SCREEN; kw_args...) = view(extract_renderable(c), screen; kw_args...)


default{T}(::T, s::Style) = default(T, s)
default{T <: Colorant}(::Type{T}, s::Style) = RGBA{Float32}(0.0f0,0.74736935f0,1.0f0,1.0f0)
default{T <: Colorant}(::Type{Vector{T}}, s::Style) = map(x->RGBA{U8}(x, 1.0), colormap("Blues", 20))