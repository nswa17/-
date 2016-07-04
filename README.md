# 進学選択シミュレーション

## 企画意図
## many to one DA algorithm
### Example

### 前提
学生が入りたい学科をリストにし, 学科が定員以下の人数の学生を成績順に受け入れる.
学生の成績分布は正規分布に従うと仮定.
<!-- 実際の成績分布のデータも利用.-->

### 学生側の選好
学科ごとにその特色を示すパラメータ(0.0~1.0)を設定し, 学生は自らの選好のパラメータと近い学科で, かつ自分への枠があるものへと応募する.

学生の選好は自らの成績と選好のパラメータに依存する.

### 学科側の選好
応募してきた人の成績順に学生を選好する.

### マッチング例

## ライブラリ使い方

```julia
using DataFrames
using PyPlot
using ExcelReaders

include("functions.jl")
student_num = 3000 #student number
mu = 0.5 #mean of scores students have (now must be standardized to [0, 1])
sigma2 = 0.2 #variance of students scores
sigma2_error = 0.05 #variance of the error the score has
preference = 0.5 #how much students want to persue their preference [0 ~ 1]

faculties_list = read_faculty_data("revised.csv", student_num)
faculty_num = length(faculties_list)
students_list = generate_students(student_num, mu, sigma2, sigma2_error, faculty_num, () -> preference)

set_prefs_faculties(faculties_list, students_list)
set_prefs_students(students_list, faculties_list)

s_prefs = generate_prefs(students_list)
s_real_prefs = get_real_prefs(students_list)
f_prefs = generate_prefs(faculties_list)
caps = generate_caps(faculties_list)

s_matched, f_matched, indptr = DA.call_match(s_prefs, f_prefs, caps)# call matching
```

### 学科
```julia
type Faculty
    name::AbstractString
    id::Int
    prefs::Array{Int, 1}
    preference::Float64
    level::Float64
    cap::Int
    available_for::Array{Int, 1}
end
```
### 学生
```julia
type Student
    id::Int
    level::Float64
    preference::Float64
    current_faculty::Int
    prefs::Array{Int, 1}
    real_prefs::Array{Int, 1}
    preference_first::Float64
end
```

### 参考

[資料excel版](https://docs.google.com/spreadsheets/d/1Eh9KEQBeeXc6N6NR-eAvHXZkE4czKjHER_Bl5_mHlWs/edit?usp=sharing)
