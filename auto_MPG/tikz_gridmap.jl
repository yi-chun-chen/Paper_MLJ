using DataFrames
using Discretizers

const OUTPUT_FILE = "output.tex"

raw = readtable("autoMPG_raw.dat", header=false)
our1 = readtable("autoMPG_exp1_ourmethod.dat", header=false)
our2 = readtable("autoMPG_exp2_ourmethod.dat", header=false)
MDL1 = readtable("autoMPG_exp1_MDLmethod.dat", header=false)

disc_our1 = Dict{Int, LinearDiscretizer}()
disc_our1[1] = LinearDiscretizer([9.0,15.25,17.65,20.9,25.65,28.9,46.6])
disc_our1[3] = LinearDiscretizer([68.0,70.5,93.5,109.0,159.5,259.0,284.5,455.0])
disc_our1[4] = LinearDiscretizer([46.0,71.5,99.0,127.0,230.0])
disc_our1[5] = LinearDiscretizer([1613.0,2115.0,2480.5,2959.5,3657.5,5140.0])
disc_our1[6] = LinearDiscretizer([8.0,12.35,13.75,16.05,22.85,24.8])


function export_plot(
	io::IO,
	var_x::Int, # variable for x axis
	var_y::Int, # variable for y axis
	disc::Dict{Int, LinearDiscretizer}, # set of linear discretizers
	pdf_pts::DataFrame, # points used to compute heatmap pdf
	scatter_pts::DataFrame; # points we will scatter on top
	colorbar_max::Float64=0.25
	)


	disc_x = disc[var_x]
	disc_y = disc[var_y]

	nbins_x = nlabels(disc_x)
	nbins_y = nlabels(disc_y)
	counts = zeros(Float64, nbins_x, nbins_y)
	for i in 1 : nrow(pdf_pts)
		x = encode(disc_x, pdf_pts[i, var_x])
		y = encode(disc_y, pdf_pts[i, var_y])
		counts[x,y] += 1
	end
	counts ./= sum(counts)

	varnamex = string('A' - 1 + var_x)
	varnamey = string('A' - 1 + var_y)

	println(io, "\\documentclass[crop,tikz]{standalone}\n")
	println(io, "\\usepackage{pgfplots}")
	println(io, "\\pgfplotsset{compat=1.12}")
	println(io, "\\begin{document}")
	println(io, "\t\\begin{tikzpicture}")
	println(io, "\t\t\\begin{axis}[")
	println(io, "\t\t\tview={0}{90},")
	println(io, "\t\t\tenlargelimits=0,")
	println(io, "\t\t\tzmin=0.0, zmax=1.0,")
	@printf(io, "\t\t\txlabel=%s,\n", varnamex)
	@printf(io, "\t\t\tylabel=%s,\n", varnamey)
	println(io, "\t\t\tcolorbar,")
	@printf(io, "\t\t\tpoint meta min=0, point meta max=%.2f,\n", colorbar_max)
	println(io, "\t\t\tcolormap={}{ gray(0cm)=(1); gray(1cm)=(0);},")
	println(io, "\t\t\tcolorbar style={")
	@printf(io, "\t\t\t        ytick={0,0.05,...,%.2f},\n", colorbar_max)
	println(io, "\t\t\t        yticklabel style={")
	println(io, "\t\t\t            text width=2.5em,")
	println(io, "\t\t\t            align=right,")
	println(io, "\t\t\t            /pgf/number format/.cd,")
	println(io, "\t\t\t                fixed,")
	println(io, "\t\t\t                fixed zerofill")
	println(io, "\t\t\t        }")
	println(io, "\t\t\t    }")
	println(io, "\t\t\t]\n")

	# plot bin rectangles
	for binx in 1 : nbins_x
		for biny in 1 : nbins_y
			x_lo = disc_x.binedges[binx]
			x_hi = disc_x.binedges[binx+1]
			y_lo = disc_y.binedges[biny]
			y_hi = disc_y.binedges[biny+1]
			prob = counts[binx, biny]

			@printf(io, "\t\t\t\\addplot3[patch,shader=faceted,patch type=rectangle] coordinates {(%.4f,%.4f,%.4f) (%.4f,%.4f,%.4f) (%.4f,%.4f,%.4f) (%.4f,%.4f,%.4f)};\n",
				x_lo, y_lo, prob, x_hi, y_lo, prob, x_hi, y_hi, prob, x_lo, y_hi, prob)
		end
		println(io, "")
	end

	# plot scatter on top
	println(io, "\t\t\t\\addplot3[mark=+, draw=none, mark size=0.7] coordinates {")
	for i in 1 : nrow(scatter_pts)
		x = scatter_pts[i, var_x]
		y = scatter_pts[i, var_y]
		@printf(io, "(%.3f,%.3f,1) ", x, y)
	end
	println(io, "};")

	println(io, "\t\t\\end{axis}")
	println(io, "\t\\end{tikzpicture}")
	println(io, "\\end{document}")
end

open(OUTPUT_FILE, "w") do fout
	export_plot(fout, 1, 3, disc_our1, our1, raw)
end
