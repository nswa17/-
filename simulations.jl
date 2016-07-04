using DataFrames
using PyPlot
using ExcelReaders

#df = readxlsheet(DataFrame, "第二段階定数.xlsx", "Sheet1")
df = readtable("第二段階定数.csv")
#df[:文科一類]
#println(names(df))

function generate_faculties_list(df)
    for name in names(df)
        println(name)
    end
end

generate_faculties_list(df)

faculty_names_and_caps
length(df)

fac_names = []
fac_caps = []
names_raw = names(df)
println(df[1, 1])
string(names_raw[2])
for i in 1:size(df, 1)
    for j in 2:length(names_raw)
        if df[i, j] != 0
            push!(fac_names, string(df[i, 1])*string(names_raw[j]))
            push!(fac_caps, df[i, j])
        end
    end
end

println()
println(fac_caps)
println(df[1, 1])
length(fac_names)

df_new = DataFrame(F=fac_names, C=fac_caps)
writetable("revised_csv", df_new)
