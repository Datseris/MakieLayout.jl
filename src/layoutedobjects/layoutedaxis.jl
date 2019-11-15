function LayoutedAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedAxis))

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
        aspect, alignment, maxsize, xticks, yticks
    )

    bboxnode = Node(BBox(0, 100, 100, 0))

    scenearea = Node(IRect(0, 0, 100, 100))

    scene = Scene(parent, scenearea, raw = true)
    limits = Node(FRect(0, 0, 100, 100))

    connect_scenearea_and_bbox!(scenearea, bboxnode, limits, aspect, alignment, maxsize)

    plots = AbstractPlot[]

    xaxislinks = LayoutedAxis[]
    yaxislinks = LayoutedAxis[]

    add_pan!(scene, limits, xpanlock, ypanlock)
    add_zoom!(scene, limits, xzoomlock, yzoomlock)

    campixel!(scene)

    # set up empty nodes for ticks and their labels
    xticksnode = Node(Point2f0[])
    xticklines = linesegments!(
        parent, xticksnode, linewidth = xtickwidth, color = xtickcolor,
        show_axis = false, visible = xticksvisible
    )[end]

    yticksnode = Node(Point2f0[])
    yticklines = linesegments!(
        parent, yticksnode, linewidth = ytickwidth, color = ytickcolor,
        show_axis = false, visible = yticksvisible
    )[end]

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        parent, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor
    )[end]

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        parent, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor
    )[end]

    nmaxticks = 20

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            xticklabelnodes[i],
            position = xticklabelposnodes[i],
            align = xticklabelalign,
            rotation = xticklabelrotation,
            textsize = xticklabelsize,
            show_axis = false,
            visible = xticklabelsvisible
        )[end]
    end

    yticklabelnodes = [Node("0") for i in 1:nmaxticks]
    yticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    yticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            yticklabelnodes[i],
            position = yticklabelposnodes[i],
            align = yticklabelalign,
            rotation = yticklabelrotation,
            textsize = yticklabelsize,
            show_axis = false,
            visible = yticklabelsvisible
        )[end]
    end

    xlabelpos = lift(scene.px_area, xlabelvisible, xticklabelsvisible,
        xticklabelspace, xticklabelpad, xticklabelsize, xlabelpadding, spinewidth, xticksvisible,
        xticksize, xtickalign) do a, xlabelvisible, xticklabelsvisible,
                xticklabelspace, xticklabelpad, xticklabelsize, xlabelpadding, spinewidth, xticksvisible,
                xticksize, xtickalign

        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0

        labelgap = spinewidth +
            xtickspace +
            (xticklabelsvisible ? xticklabelspace + xticklabelpad : 0f0) +
            xlabelpadding

        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area, ylabelvisible, yticklabelsvisible,
        yticklabelspace, yticklabelpad, yticklabelsize, ylabelpadding, spinewidth, yticksvisible,
        yticksize, ytickalign) do a, ylabelvisible, yticklabelsvisible,
                yticklabelspace, yticklabelpad, yticklabelsize, ylabelpadding, spinewidth, yticksvisible,
                yticksize, ytickalign

        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0

        labelgap = spinewidth +
            ytickspace +
            (yticklabelsvisible ? yticklabelspace + yticklabelpad : 0f0) +
            ylabelpadding

        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    xlabeltext = text!(
        parent, xlabel, textsize = xlabelsize, color = xlabelcolor,
        position = xlabelpos, show_axis = false, visible = xlabelvisible,
        align = (:center, :top)
    )[end]

    ylabeltext = text!(
        parent, ylabel, textsize = ylabelsize, color = ylabelcolor,
        position = ylabelpos, rotation = pi/2, show_axis = false,
        visible = ylabelvisible, align = (:center, :bottom)
    )[end]

    titlepos = lift(scene.px_area, titlegap, titlealign) do a, titlegap, align
        x = if align == :center
            a.origin[1] + a.widths[1] / 2
        elseif align == :left
            a.origin[1]
        elseif align == :right
            a.origin[1] + a.widths[1]
        else
            error("Title align $align not supported.")
        end

        Point2(x, a.origin[2] + a.widths[2] + titlegap)
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

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    xtickvalues = Node(Float32[])
    ytickvalues = Node(Float32[])

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

        thisxlims = (limox, limox + limw)
        thisylims = (limoy, limoy + limh)

        bothlinks = intersect(xaxislinks, yaxislinks)
        xlinks = setdiff(xaxislinks, yaxislinks)
        ylinks = setdiff(yaxislinks, xaxislinks)

        for link in bothlinks
            otherlims = link.limits[]
            if lims != otherlims
                link.limits[] = lims
            end
        end

        for xlink in xlinks
            otherlims = xlink.limits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisxlims != otherxlims
                xlink.limits[] = BBox(thisxlims[1], thisxlims[2], otherylims[2], otherylims[1])
            end
        end

        for ylink in ylinks
            otherlims = ylink.limits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisylims != otherylims
                ylink.limits[] = BBox(otherxlims[1], otherxlims[2], thisylims[2], thisylims[1])
            end
        end
    end

    # change tick values with scene, limits and tick distance preference

    onany(pixelarea(scene), limits, xticks) do pxa, limits, xticks
        limox = limits.origin[1]
        limw = limits.widths[1]
        px_w = pxa.widths[1]

        xtickvalues[] = compute_tick_values(xticks, limox, limox + limw, px_w)
    end

    onany(pixelarea(scene), limits, yticks) do pxa, limits, yticks
        limoy = limits.origin[2]
        limh = limits.widths[2]
        px_h = pxa.widths[2]

        ytickvalues[] = compute_tick_values(yticks, limoy, limoy + limh, px_h)
    end

    xtickpositions = Node(Point2f0[])
    xtickstrings = Node(String[])

    # change tick positions when tick values change, also update grid and tick strings

    on(xtickvalues) do xtickvalues
        limox = limits[].origin[1]
        limw = limits[].widths[1]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        xfractions = (xtickvalues .- limox) ./ limw
        xticks_scene = px_ox .+ px_w .* xfractions

        xtickpos = [Point(x, px_oy) for x in xticks_scene]
        topxtickpositions = [xtp + Point2f0(0, px_h) for xtp in xtickpos]

        xgridnode[] = interleave_vectors(xtickpos, topxtickpositions)

        # now trigger updates
        xtickpositions[] = xtickpos

        xtickstrings[] = get_tick_labels(xticks[], xtickvalues)
    end

    ytickpositions = Node(Point2f0[])
    ytickstrings = Node(String[])

    on(ytickvalues) do ytickvalues
        limoy = limits[].origin[2]
        limh = limits[].widths[2]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        yfractions = (ytickvalues .- limoy) ./ limh
        yticks_scene = px_oy .+ px_h .* yfractions

        ytickpos = [Point(px_ox, y) for y in yticks_scene]
        rightytickpositions = [ytp + Point2f0(px_w, 0) for ytp in ytickpos]

        ygridnode[] = interleave_vectors(ytickpos, rightytickpositions)

        # now trigger updates
        ytickpositions[] = ytickpos

        ytickstrings[] = get_tick_labels(yticks[], ytickvalues)
    end

    # update tick labels when strings or properties change


    onany(xtickstrings, xticklabelpad, spinewidth, xticklabelsvisible, xticksize, xtickalign, xticksvisible) do xtickstrings,
            xticklabelpad, spinewidth, xticklabelsvisible, xticksize, xtickalign, xticksvisible

        nxticks = length(xtickvalues[])

        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0

        for i in 1:length(xticklabels)
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]

                xticklabelgap = spinewidth + xtickspace + xticklabelpad

                xticklabelposnodes[i][] = xtickpositions[][i] +
                    Point(0f0, -xticklabelgap)
                xticklabels[i].visible = true && xticklabelsvisible
            else
                xticklabels[i].visible = false
            end
        end
    end

    onany(ytickstrings, yticklabelpad, spinewidth, yticklabelsvisible, yticksize, ytickalign, yticksvisible) do ytickstrings,
            yticklabelpad, spinewidth, yticklabelsvisible, yticksize, ytickalign, yticksvisible

        nyticks = length(ytickvalues[])

        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0

        for i in 1:length(yticklabels)
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]

                yticklabelgap = spinewidth + ytickspace + yticklabelpad

                yticklabelposnodes[i][] = ytickpositions[][i] +
                    Point(-yticklabelgap, 0f0)
                yticklabels[i].visible = true && yticklabelsvisible
            else
                yticklabels[i].visible = false
            end
        end
    end

    # update tick geometry when positions or parameters change

    onany(xtickpositions, xtickalign, xticksize, spinewidth) do xtickpositions,
            xtickalign, xticksize, spinewidth

        xtickstarts = [xtp + Point(0f0, xtickalign * xticksize - 0.5f0 * spinewidth) for xtp in xtickpositions]
        xtickends = [t + Point(0f0, -xticksize) for t in xtickstarts]

        xticksnode[] = interleave_vectors(xtickstarts, xtickends)
    end

    onany(ytickpositions, ytickalign, yticksize, spinewidth) do ytickpositions,
            ytickalign, yticksize, spinewidth

        ytickstarts = [ytp + Point(ytickalign * yticksize - 0.5f0 * spinewidth, 0f0) for ytp in ytickpositions]
        ytickends = [t + Point(-yticksize, 0f0) for t in ytickstarts]

        yticksnode[] = interleave_vectors(ytickstarts, ytickends)
    end



    function compute_protrusions(xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
                ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding,
                ylabelpadding, xticklabelsize, yticklabelsize, xticklabelsvisible,
                yticklabelsvisible, xticksize, yticksize, xticksvisible, yticksvisible,
                xticklabelspace, yticklabelspace, xticklabelpad, yticklabelpad, xtickalign, ytickalign, spinewidth)

        top = titlevisible ? boundingbox(titlet).widths[2] + titlegap : 0f0

        xlabelspace = xlabelvisible ? boundingbox(xlabeltext).widths[2] + xlabelpadding : 0f0
        xspinespace = spinewidth
        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0
        xticklabelgap = xticklabelsvisible ? xticklabelspace + xticklabelpad : 0f0

        bottom = xspinespace + xtickspace + xticklabelgap + xlabelspace

        ylabelspace = ylabelvisible ? boundingbox(ylabeltext).widths[1] + ylabelpadding : 0f0
        yspinespace = spinewidth
        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0
        yticklabelgap = yticklabelsvisible ? yticklabelspace + yticklabelpad : 0f0

        left = yspinespace + ytickspace + yticklabelgap + ylabelspace

        right = 0f0

        (left, right, top, bottom)
    end

    protrusions = lift(compute_protrusions,
        xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelspace,
        yticklabelspace, xticklabelpad, yticklabelpad, xtickalign, ytickalign, spinewidth)

    needs_update = Node(true)

    # trigger a layout update whenever the protrusions change
    on(protrusions) do prot
        needs_update[] = true
    end

    la = LayoutedAxis(parent, scene, plots, xaxislinks, yaxislinks, bboxnode, limits,
        protrusions, needs_update, attrs)

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
    Showoff.showoff(tickvalues, :plain)
end

function get_tick_labels(ticks::ManualTicks, tickvalues)
    # remove labels of ticks that are not shown because the limits cut them off
    String[ticks.labels[findfirst(x -> x == tv, ticks.values)] for tv in tickvalues]
end

function AbstractPlotting.scatter!(la::LayoutedAxis, args...; kwargs...)
    plot = scatter!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.lines!(la::LayoutedAxis, args...; kwargs...)
    plot = lines!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.image!(la::LayoutedAxis, args...; kwargs...)
    plot = image!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.poly!(la::LayoutedAxis, args...; kwargs...)
    plot = poly!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function AbstractPlotting.meshscatter!(la::LayoutedAxis, args...; kwargs...)
    plot = meshscatter!(la.scene, args...; show_axis=false, kwargs...)[end]
    push!(la.plots, plot)
    autolimits!(la)
    plot
end

function bboxunion(bb1, bb2)

    o1 = bb1.origin
    o2 = bb2.origin
    e1 = bb1.origin + bb1.widths
    e2 = bb2.origin + bb2.widths

    o = min.(o1, o2)
    e = max.(e1, e2)

    BBox(o[1], e[1], e[2], o[2])
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
    (limsordered[1] - dleft, limsordered[2] + dright)
end

function getlimits(la::LayoutedAxis, dim)
    lim = if length(la.plots) > 0
        bbox = BBox(boundingbox(la.plots[1]))
        templim = (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim])
        for p in la.plots[2:end]
            bbox = BBox(boundingbox(p))
            templim = limitunion(templim, (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim]))
        end
        templim
    else
        nothing
    end
end

getxlimits(la::LayoutedAxis) = getlimits(la, 1)
getylimits(la::LayoutedAxis) = getlimits(la, 2)


function autolimits!(la::LayoutedAxis)

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
        xlims = (0f0, 1f0)
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
        ylims = (0f0, 1f0)
    else
        ylims = expandlimits(ylims,
            la.attributes.yautolimitmargin[][1],
            la.attributes.yautolimitmargin[][2])
    end

    bbox = BBox(xlims[1], xlims[2], ylims[2], ylims[1])
    la.limits[] = bbox
end

function linkxaxes!(a::LayoutedAxis, others...)
    axes = LayoutedAxis[a; others...]

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

function linkyaxes!(a::LayoutedAxis, others...)
    axes = LayoutedAxis[a; others...]

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

function add_pan!(scene::SceneLike, limits, xpanlock, ypanlock)
    startpos = Base.RefValue((0.0, 0.0))
    pan = Mouse.right
    xzoom = Keyboard.x
    yzoom = Keyboard.y
    e = events(scene)
    on(
        camera(scene),
        # Node.((scene, cam, startpos))...,
        Node.((scene, startpos))...,
        e.mousedrag
    ) do scene, startpos, dragging
        # pan = cam.panbutton[]
        mp = e.mouseposition[]
        if ispressed(scene, pan) && is_mouseinside(scene)
            window_area = pixelarea(scene)[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, pan)
                diff = startpos[] .- mp
                startpos[] = mp
                pxa = scene.px_area[]
                diff_fraction = Vec2f0(diff) ./ Vec2f0(widths(pxa))

                diff_limits = diff_fraction .* widths(limits[])

                xori, yori = Vec2f0(limits[].origin) .+ Vec2f0(diff_limits)

                if xpanlock[] || ispressed(scene, yzoom)
                    xori = limits[].origin[1]
                end

                if ypanlock[] || ispressed(scene, xzoom)
                    yori = limits[].origin[2]
                end

                limits[] = FRect(Vec2f0(xori, yori), widths(limits[]))
            end
        end
        return
    end
end

function add_zoom!(scene::SceneLike, limits, xzoomlock, yzoomlock)

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

            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.x)
                limits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.y)
                limits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                limits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end
end

function add_reset_limits!(la::LayoutedAxis)
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