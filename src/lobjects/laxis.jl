function LAxis(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LAxis))

    @extract attrs (
        xlabel, ylabel, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        xlabelcolor, ylabelcolor, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelspace,
        yticklabelspace, xticklabelpad, yticklabelpad, xticklabelrotation, yticklabelrotation, xticklabelalign,
        yticklabelalign, xtickalign, ytickalign, xtickwidth, ytickwidth, xtickcolor,
        ytickcolor, xpanlock, ypanlock, xzoomlock, yzoomlock, spinewidth, xgridvisible, ygridvisible,
        xgridwidth, ygridwidth, xgridcolor, ygridcolor, topspinevisible, rightspinevisible, leftspinevisible,
        bottomspinevisible, topspinecolor, leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, halign, valign, maxsize, xticks, yticks, panbutton, xpankey, ypankey, xzoomkey, yzoomkey,
        xaxisposition, yaxisposition, xoppositespinevisible, yoppositespinevisible
    )

    decorations = Dict{Symbol, Any}()

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    computedsize = computedsizenode!(sizeattrs)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs)

    limits = Node(FRect(0, 0, 100, 100))

    scenearea = sceneareanode!(finalbbox, limits, aspect)

    scene = Scene(parent, scenearea, raw = true)

    block_limit_linking = Node(false)

    plots = AbstractPlot[]

    xaxislinks = LAxis[]
    yaxislinks = LAxis[]

    add_pan!(scene, limits, xpanlock, ypanlock, panbutton, xpankey, ypankey)
    add_zoom!(scene, limits, xzoomlock, yzoomlock, xzoomkey, yzoomkey)

    campixel!(scene)

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        parent, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor
    )[end]
    decorations[:xgridlines] = xgridlines

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        parent, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor
    )[end]
    decorations[:ygridlines] = ygridlines

    # connect camera, plot size or limit changes to the axis decorations

    onany(pixelarea(scene), limits) do pxa, lims

        px_ox, px_oy = pxa.origin
        px_w, px_h = pxa.widths

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = lims.origin
        limw, limh = lims.widths

        projection = AbstractPlotting.orthographicprojection(
            limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection

        update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, lims)
    end

    xaxis_endpoints = lift(xaxisposition, scene.px_area) do xaxisposition, area
        if xaxisposition == :bottom
            bottomline(BBox(area))
        elseif xaxisposition == :top
            topline(BBox(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    yaxis_endpoints = lift(yaxisposition, scene.px_area) do yaxisposition, area
        if yaxisposition == :left
            leftline(BBox(area))
        elseif yaxisposition == :right
            rightline(BBox(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    xaxis_flipped = lift(x->x == :top, xaxisposition)
    yaxis_flipped = lift(x->x == :right, yaxisposition)

    xaxis = LineAxis(parent, endpoints = xaxis_endpoints, limits = lift(xlimits, limits),
        flipped = xaxis_flipped, ticklabelalign = xticklabelalign, labelsize = xlabelsize,
        labelpadding = xlabelpadding, ticklabelpad = xticklabelpad, labelvisible = xlabelvisible,
        label = xlabel, labelcolor = xlabelcolor, tickalign = xtickalign,
        ticklabelspace = xticklabelspace, ticks = xticks)
    decorations[:xaxis] = xaxis

    yaxis  =  LineAxis(parent, endpoints = yaxis_endpoints, limits = lift(ylimits, limits),
        flipped = yaxis_flipped, ticklabelalign = yticklabelalign, labelsize = ylabelsize,
        labelpadding = ylabelpadding, ticklabelpad = yticklabelpad, labelvisible = ylabelvisible,
        label = ylabel, labelcolor = ylabelcolor, tickalign = ytickalign,
        ticklabelspace = yticklabelspace, ticks = yticks)
    decorations[:yaxis] = yaxis

    xoppositelinepoints = lift(scene.px_area, spinewidth, xaxisposition) do r, sw, xaxpos
        if xaxpos == :top
            y = bottom(r) - 0.5f0 * sw
            p1 = Point2(left(r) - sw, y)
            p2 = Point2(right(r) + sw, y)
            [p1, p2]
        else
            y = top(r) + 0.5f0 * sw
            p1 = Point2(left(r) - sw, y)
            p2 = Point2(right(r) + sw, y)
            [p1, p2]
        end
    end

    yoppositelinepoints = lift(scene.px_area, spinewidth, yaxisposition) do r, sw, yaxpos
        if yaxpos == :right
            x = left(r) - 0.5f0 * sw
            p1 = Point2(x, bottom(r) - sw)
            p2 = Point2(x, top(r) + sw)
            [p1, p2]
        else
            x = right(r) + 0.5f0 * sw
            p1 = Point2(x, bottom(r) - sw)
            p2 = Point2(x, top(r) + sw)
            [p1, p2]
        end
    end

    xoppositeline = lines!(parent, xoppositelinepoints, linewidth = spinewidth, visible = xoppositespinevisible)
    decorations[:xoppositeline] = xoppositeline
    yoppositeline = lines!(parent, yoppositelinepoints, linewidth = spinewidth, visible = yoppositespinevisible)
    decorations[:yoppositeline] = yoppositeline

    on(xaxis.tickpositions) do tickpos
        pxheight = height(scene.px_area[])
        offset = xaxisposition[] == :bottom ? pxheight : -pxheight
        opposite_tickpos = tickpos .+ Ref(Point2f0(0, offset))
        xgridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    on(yaxis.tickpositions) do tickpos
        pxwidth = width(scene.px_area[])
        offset = yaxisposition[] == :left ? pxwidth : -pxwidth
        opposite_tickpos = tickpos .+ Ref(Point2f0(offset, 0))
        ygridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    titlepos = lift(scene.px_area, titlegap, titlealign, xaxisposition, xaxis.protrusion) do a,
            titlegap, align, xaxisposition, xaxisprotrusion

        x = if align == :center
            a.origin[1] + a.widths[1] / 2
        elseif align == :left
            a.origin[1]
        elseif align == :right
            a.origin[1] + a.widths[1]
        else
            error("Title align $align not supported.")
        end

        yoffset = top(a) + titlegap + (xaxisposition == :top ? xaxisprotrusion : 0f0)

        Point2(x, yoffset)
    end

    titlealignnode = lift(titlealign) do align
        (align, :bottom)
    end

    titlet = text!(
        parent, title,
        position = titlepos,
        visible = titlevisible,
        textsize = titlesize,
        align = titlealignnode,
        font = titlefont,
        show_axis=false)[end]
    decorations[:title] = titlet

    function compute_protrusions(title, titlesize, titlegap, titlevisible, spinewidth,
                xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition)

        top = titlevisible ? boundingbox(titlet).widths[2] + titlegap : 0f0

        bottom = spinewidth

        if xaxisposition == :bottom
            bottom += xaxisprotrusion
        else
            top += xaxisprotrusion
        end

        left = spinewidth

        right = spinewidth

        if yaxisposition == :left
            left += yaxisprotrusion
        else
            right += yaxisprotrusion
        end

        RectSides{Float32}(left, right, bottom, top)
    end

    protrusions = lift(compute_protrusions,
        title, titlesize, titlegap, titlevisible, spinewidth,
        xaxis.protrusion, yaxis.protrusion, xaxisposition, yaxisposition)

    needs_update = Node(true)

    # trigger a layout update whenever the protrusions change
    on(protrusions) do prot
        needs_update[] = true
    end

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    suggestedbbox[] = suggestedbbox[]

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    la = LAxis(parent, scene, plots, xaxislinks, yaxislinks, limits,
        layoutnodes, needs_update, attrs, block_limit_linking, decorations)

    add_reset_limits!(la)

    la
end

function compute_tick_values(ticks::T, vmin, vmax, pxwidth) where T
    error("No behavior implemented for ticks of type $T")
end

function compute_tick_values(ticks::AutoLinearTicks, vmin, vmax, pxwidth)
    locateticks(vmin, vmax, pxwidth, ticks.idealtickdistance)
end

function compute_tick_values(ticks::ManualTicks, vmin, vmax, pxwidth)
    # only show manual ticks that fit in the value range
    filter(ticks.values) do v
        vmin <= v <= vmax
    end
end

function get_tick_labels(ticks::T, tickvalues) where T
    error("No behavior implemented for ticks of type $T")
end

function get_tick_labels(ticks::AutoLinearTicks, tickvalues)

    # take difference of first two values (they are equally spaced anyway)
    dif = diff(view(tickvalues, 1:2))[1]
    # whats the exponent of the difference?
    expo = log10(dif)

    # all difs bigger than one should be integers with the normal step sizes
    dif_is_integer = dif > 0.99999
    # this condition means that the exponent is close to an integer, so the numbers
    # would have a trailing zero with the safety applied
    exp_is_integer = isapprox(abs(expo) % 1 - 1, 0, atol=1e-6)

    safety_expo_int = if dif_is_integer || exp_is_integer
        Int(round(expo))
    else
        safety_expo_int = Int(round(expo)) - 1
    end
    # for e.g. 1.32 we want 2 significant digits, so we invert the exponent
    # and set precision to 0 for everything that is an integer
    sigdigits = max(0, -safety_expo_int)

    strings = map(tickvalues) do v
        Formatting.format(v, precision=sigdigits)
    end
end

function get_tick_labels(ticks::ManualTicks, tickvalues)
    # remove labels of ticks that are not shown because the limits cut them off
    String[ticks.labels[findfirst(x -> x == tv, ticks.values)] for tv in tickvalues]
end

function AbstractPlotting.plot!(
        la::LAxis, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(la.scene, P, attributes, args...; kw_attributes...)[end]

    # axiscontent = AxisContent(plot, xautolimit=xautolimit, yautolimit=yautolimit)
    axiscontent = AxisContent(plot)
    push!(la.plots, axiscontent)
    autolimits!(la)
    plot

end

function align_to_bbox!(la::LAxis, bb::BBox)
    la.layoutnodes.suggestedbbox[] = bb
end

protrusionnode(la::LAxis) = la.layoutnodes.protrusions
computedsizenode(la::LAxis) = la.layoutnodes.computedsize

function bboxunion(bb1, bb2)

    o1 = bb1.origin
    o2 = bb2.origin
    e1 = bb1.origin + bb1.widths
    e2 = bb2.origin + bb2.widths

    o = min.(o1, o2)
    e = max.(e1, e2)

    BBox(o[1], e[1], o[2], e[2])
end

function expandbboxwithfractionalmargins(bb, margins)
    newwidths = bb.widths .* (1f0 .+ margins)
    diffs = newwidths .- bb.widths
    neworigin = bb.origin .- (0.5f0 .* diffs)
    FRect2D(neworigin, newwidths)
end

function limitunion(lims1, lims2)
    (min(lims1..., lims2...), max(lims1..., lims2...))
end

function expandlimits(lims, marginleft, marginright)
    limsordered = (min(lims[1], lims[2]), max(lims[1], lims[2]))
    w = limsordered[2] - limsordered[1]
    dleft = w * marginleft
    dright = w * marginright
    lims = (limsordered[1] - dleft, limsordered[2] + dright)

    # guard against singular limits from something like a vline or hline
    if lims[2] - lims[1] == 0
        lims = lims .+ (-10, 10)
    end
    lims
end

function getlimits(la::LAxis, dim)

    limitables = if dim == 1
        filter(p -> p.attributes.xautolimit[], la.plots)
    elseif dim == 2
        filter(p -> p.attributes.yautolimit[], la.plots)
    end

    lim = if length(limitables) > 0
        bbox = BBox(boundingbox(limitables[1].content))
        templim = (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim])
        for p in limitables[2:end]
            bbox = BBox(boundingbox(p.content))
            templim = limitunion(templim, (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim]))
        end
        templim
    else
        nothing
    end
end

getxlimits(la::LAxis) = getlimits(la, 1)
getylimits(la::LAxis) = getlimits(la, 2)

function update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, lims)

    thisxlims = xlimits(lims)
    thisylims = ylimits(lims)

    # only change linked axis if not prohibited from doing so because
    # we're currently being updated by another axis' link
    if !block_limit_linking[]

        bothlinks = intersect(xaxislinks, yaxislinks)
        xlinks = setdiff(xaxislinks, yaxislinks)
        ylinks = setdiff(yaxislinks, xaxislinks)

        for link in bothlinks
            otherlims = link.limits[]
            if lims != otherlims
                link.block_limit_linking[] = true
                link.limits[] = lims
                link.block_limit_linking[] = false
            end
        end

        for xlink in xlinks
            otherlims = xlink.limits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisxlims != otherxlims
                xlink.block_limit_linking[] = true
                xlink.limits[] = BBox(thisxlims[1], thisxlims[2], otherylims[1], otherylims[2])
                xlink.block_limit_linking[] = false
            end
        end

        for ylink in ylinks
            otherlims = ylink.limits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisylims != otherylims
                ylink.block_limit_linking[] = true
                ylink.limits[] = BBox(otherxlims[1], otherxlims[2], thisylims[1], thisylims[2])
                ylink.block_limit_linking[] = false
            end
        end
    end
end


function autolimits!(la::LAxis)

    xlims = getxlimits(la)
    for link in la.xaxislinks
        if isnothing(xlims)
            xlims = getxlimits(link)
        else
            newxlims = getxlimits(link)
            if !isnothing(newxlims)
                xlims = limitunion(xlims, newxlims)
            end
        end
    end
    if isnothing(xlims)
        xlims = (la.limits[].origin[1], la.limits[].origin[1] + la.limits[].widths[1])
    else
        xlims = expandlimits(xlims,
            la.attributes.xautolimitmargin[][1],
            la.attributes.xautolimitmargin[][2])
    end

    ylims = getylimits(la)
    for link in la.yaxislinks
        if isnothing(ylims)
            ylims = getylimits(link)
        else
            newylims = getylimits(link)
            if !isnothing(newylims)
                ylims = limitunion(ylims, newylims)
            end
        end
    end
    if isnothing(ylims)
        ylims = (la.limits[].origin[2], la.limits[].origin[2] + la.limits[].widths[2])
    else
        ylims = expandlimits(ylims,
            la.attributes.yautolimitmargin[][1],
            la.attributes.yautolimitmargin[][2])
    end

    bbox = BBox(xlims[1], xlims[2], ylims[1], ylims[2])
    la.limits[] = bbox
end

function linkxaxes!(a::LAxis, others...)
    axes = LAxis[a; others...]

    for i in 1:length(axes)-1
        for j in i+1:length(axes)
            axa = axes[i]
            axb = axes[j]

            if axa ∉ axb.xaxislinks
                push!(axb.xaxislinks, axa)
            end
            if axb ∉ axa.xaxislinks
                push!(axa.xaxislinks, axb)
            end
        end
    end
end

function linkyaxes!(a::LAxis, others...)
    axes = LAxis[a; others...]

    for i in 1:length(axes)-1
        for j in i+1:length(axes)
            axa = axes[i]
            axb = axes[j]

            if axa ∉ axb.yaxislinks
                push!(axb.yaxislinks, axa)
            end
            if axb ∉ axa.yaxislinks
                push!(axa.yaxislinks, axb)
            end
        end
    end
end

function add_pan!(scene::SceneLike, limits, xpanlock, ypanlock, panbutton, xpankey, ypankey)
    startpos = Base.RefValue((0.0, 0.0))
    e = events(scene)
    on(
        camera(scene),
        # Node.((scene, cam, startpos))...,
        Node.((scene, startpos))...,
        e.mousedrag
    ) do scene, startpos, dragging
        mp = e.mouseposition[]
        if ispressed(scene, panbutton[]) && is_mouseinside(scene)
            window_area = pixelarea(scene)[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, panbutton[])
                diff = startpos[] .- mp
                startpos[] = mp
                pxa = scene.px_area[]
                diff_fraction = Vec2f0(diff) ./ Vec2f0(widths(pxa))

                diff_limits = diff_fraction .* widths(limits[])

                xori, yori = Vec2f0(limits[].origin) .+ Vec2f0(diff_limits)

                if xpanlock[] || ispressed(scene, ypankey[])
                    xori = limits[].origin[1]
                end

                if ypanlock[] || ispressed(scene, xpankey[])
                    yori = limits[].origin[2]
                end

                limits[] = FRect(Vec2f0(xori, yori), widths(limits[]))
            end
        end
        return
    end
end

function add_zoom!(scene::SceneLike, limits, xzoomlock, yzoomlock, xzoomkey, yzoomkey)

    e = events(scene)
    cam = camera(scene)
    on(cam, e.scroll) do x
        # @extractvalue cam (zoomspeed, zoombutton, area)
        zoomspeed = 0.10f0
        zoombutton = nothing
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) && AbstractPlotting.is_mouseinside(scene)
            pa = pixelarea(scene)[]

            # don't let z go negative
            z = max(0.1f0, 1f0 + (zoom * zoomspeed))

            # limits[] = FRect(limits[].origin..., (limits[].widths .* 0.99)...)
            mp_fraction = (Vec2f0(e.mouseposition[]) - minimum(pa)) ./ widths(pa)

            mp_data = limits[].origin .+ mp_fraction .* limits[].widths

            xorigin = limits[].origin[1]
            yorigin = limits[].origin[2]

            xwidth = limits[].widths[1]
            ywidth = limits[].widths[2]

            newxwidth = xzoomlock[] ? xwidth : xwidth * z
            newywidth = yzoomlock[] ? ywidth : ywidth * z

            newxorigin = xzoomlock[] ? xorigin : xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yzoomlock[] ? yorigin : yorigin + mp_fraction[2] * (ywidth - newywidth)

            if AbstractPlotting.ispressed(scene, xzoomkey[])
                limits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, yzoomkey[])
                limits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                limits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end
end

function add_reset_limits!(la::LAxis)
    scene = la.scene
    e = events(scene)
    cam = camera(scene)
    on(cam, e.mousebuttons) do buttons
        if ispressed(scene, AbstractPlotting.Mouse.left) && AbstractPlotting.is_mouseinside(scene)
            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.left_control)
                autolimits!(la)
            end
        end
        return
    end
end

function Base.getproperty(la::LAxis, s::Symbol)
    if s in fieldnames(LAxis)
        getfield(la, s)
    else
        la.attributes[s]
    end
end

function Base.setproperty!(la::LAxis, s::Symbol, value)
    if s in fieldnames(LAxis)
        setfield!(la, s, value)
    else
        la.attributes[s][] = value
    end
end

function Base.propertynames(la::LAxis)
    [fieldnames(LAxis)..., keys(la.attributes)...]
end

defaultlayout(la::LAxis) = ProtrusionLayout(la)

function hidexdecorations!(la::LAxis)
    la.xlabelvisible = false
    la.xticklabelsvisible = false
    la.xticksvisible = false
end

function hideydecorations!(la::LAxis)
    la.ylabelvisible = false
    la.yticklabelsvisible = false
    la.yticksvisible = false
end


function tight_yticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.decorations[:yaxis])
end

function tight_xticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.decorations[:xaxis])
end

function tight_ticklabel_spacing!(la::LAxis)
    tight_xticklabel_spacing!(la)
    tight_yticklabel_spacing!(la)
end

function AxisContent(plot; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(AxisContent))

    AxisContent(plot, attrs)
end