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

length(df)

fac_names = []
fac_caps = []
fac_available_for = []
ids = []
names_raw = names(df)
println(df[1, 1])
string(names_raw)
c = 1
for i in 1:size(df, 1)
    for j in 2:length(names_raw)
        if df[i, j] != 0
            push!(fac_names, string(df[i, 1])*string(names_raw[j]))
            push!(fac_caps, df[i, j])
            push!(fac_available_for, j-1)
            push!(ids, c)
            c += 1
        end
    end
end

println()
println(fac_caps)
println(df[1, 1])
length(fac_names)

df_new = DataFrame(ID=ids, F=fac_names, C=fac_caps, A=fac_available_for)
writetable("revised.csv", df_new)
