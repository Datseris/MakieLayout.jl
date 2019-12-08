using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 2;
        parent = scene,
        rowsizes = Relative(1),
        colsizes = [Auto(), Fixed(200)],
        addedcolgaps = Fixed(30),
        alignmode = Outside(30, 30, 30, 30)
    )

    gl = maingl[1, 1] = GridLayout(
        3, 3;
        rowsizes = Relative(1/3),
        colsizes = Auto(),
        addedcolgaps = Fixed(20),
        addedrowgaps = Fixed(20),
        alignmode = Outside()
    )

    las = []
    for i in 1:3, j in 1:3
        # la =
        # al = ProtrusionLayout(gl, la.protrusions, la.bboxnode)
        la = gl[i, j] = LAxis(scene)
        sc = scatter!(
            la,
            rand(100, 2) .* 90 .+ 5,
            color=RGBf0(rand(3)...),
            raw=true, markersize=5)
        push!(las, la)
    end

    # buttons need change in abstractplotting to correctly update frame position

    glside = maingl[1, 2] = GridLayout(7, 1, alignmode=Outside())

    but = glside[1, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Titles")
    on(but.clicks) do c
        for la in las
            la.attributes.titlevisible[] = !la.attributes.titlevisible[]
        end
    end

    but2 = glside[2, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Labels")
    on(but2.clicks) do c
        for la in las
            la.attributes.xlabelvisible[] = !la.attributes.xlabelvisible[]
            la.attributes.ylabelvisible[] = !la.attributes.ylabelvisible[]
        end
    end

    but3 = glside[3, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Ticklabels")
    on(but3.clicks) do c
        for la in las
            la.attributes.xticklabelsvisible[] = !la.attributes.xticklabelsvisible[]
            la.attributes.yticklabelsvisible[] = !la.attributes.yticklabelsvisible[]
        end
    end

    but4 = glside[4, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Ticks")
    on(but4.clicks) do c
        t1 = time()
        with_updates_suspended(maingl) do
            for la in las
                la.attributes.xticksvisible[] = !la.attributes.xticksvisible[]
                la.attributes.yticksvisible[] = !la.attributes.yticksvisible[]
            end
        end
        println(time() - t1)
    end

    but5 = glside[5, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Tick Align")
    on(but5.clicks) do c
        t1 = time()
        maingl.block_updates = true
        for la in las
            la.attributes.xtickalign[] = la.attributes.xtickalign[] == 1 ? 0 : 1
            la.attributes.ytickalign[] = la.attributes.ytickalign[] == 1 ? 0 : 1
        end
        maingl.block_updates = true
        maingl.needs_update[] = true
        println(time() - t1)
    end

    but6 = glside[6, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Grids")
    on(but6.clicks) do c
        for la in las
            la.attributes.xgridvisible[] = !la.attributes.xgridvisible[]
            la.attributes.ygridvisible[] = !la.attributes.ygridvisible[]
        end
    end

    but7 = glside[7, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Spines")
    on(but7.clicks) do c
        for la in las
            la.attributes.topspinevisible[] = !la.attributes.topspinevisible[]
            la.attributes.leftspinevisible[] = !la.attributes.leftspinevisible[]
            la.attributes.bottomspinevisible[] = !la.attributes.bottomspinevisible[]
            la.attributes.rightspinevisible[] = !la.attributes.rightspinevisible[]
        end
    end
end

map(la -> la.attributes.xticklabelpad = 5, las)
map(la -> la.attributes.xlabelpadding = 0, las)
map(la -> la.attributes.spinewidth = 1, las)
map(la -> la.attributes.xticklabelrotation = pi/2, las)
map(la -> la.attributes.xticklabelalign = (:right, :center), las)
map(la -> la.attributes.xticklabelspace = 50, las)


begin
    begin
        for i in 1:9
            las[i].attributes.ylabelvisible[] = false
            las[i].attributes.xlabelvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.yticklabelsvisible[] = false
            las[i].attributes.xticklabelsvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.titlevisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.ylabelvisible[] = true
            las[i].attributes.xlabelvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.yticklabelsvisible[] = true
            las[i].attributes.xticklabelsvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.titlevisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.title[] = "Big\nTitle"
            las[i].attributes.ylabel[] = "Big\ny label"
            las[i].attributes.xlabel[] = "Big\nx label"
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.title[] = "Title"
            las[i].attributes.ylabel[] = "y label"
            las[i].attributes.xlabel[] = "x label"
            sleep(0.05)
        end
    end
    begin
        for i in 1:9
            las[i].attributes.ylabelsize[] = 30
            las[i].attributes.xlabelsize[] = 30
            las[i].attributes.yticklabelsize[] = 30
            las[i].attributes.xticklabelsize[] = 30
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.ylabelsize[] = 20
            las[i].attributes.xlabelsize[] = 20
            las[i].attributes.yticklabelsize[] = 20
            las[i].attributes.xticklabelsize[] = 20
            sleep(0.05)
        end
    end
end