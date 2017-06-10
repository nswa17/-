# ShingakuMatching.jl
tools for simulation of 東大第二段階進学選択 in Julia

### 前提
学生が入りたい学科をリストにし, 学科が定員以下の人数の学生を成績順に受け入れる.

### マッチング例

## Docs

### Types

#### Faculty
```julia
type Faculty
    id::Int
    cap::Int
    available_for::Vector{Int}#その類の人のみがfacultyに応募できる.
end
```

#### Student
```julia
type Student
    id::Int
    current_faculty::Int#所属する科類 文一 => 1, 理一 => 4
end
```

### Functions

#### read_faculties
```julia
read_faculties{T <: AbstractString}([filename::T])
```

第二段階定数データの取り込み.

returns faculties::Vector{Faculty}

#### generate_students
```julia
generate_students(students_num::Int[, current_faculties::Vector{Int}])
```

第二引数未設定の場合科類をランダムに割り当てる.

returns students::Vector{Student}

#### get_random_prefs
```julia
get_random_prefs(
    faculties::Vector{Faculty},
    students::Vector{Student}
    [;beta::Float64,
    gamma::Float64,
    faculty_vertical_dist::UnivariateDistribution,
    student_vertical_dist::UnivariateDistribution,
    faculty_relative_dist::UnivariateDistribution,
    student_relative_dist::UnivariateDistribution,
    error_dist::UnivariateDistribution,
    seed::Int,
    max_candidates::Int]
    )
```

Random Utility Model(Hitsch et al. (2010))の下でpreferenceをランダムに生成.

具体的には, 全アクターが２つのcharacteristics, $x^A$ and $x^D$をもち, $i$が$j$とマッチする事による効用は,

u_i(j) = beta * x^A_j - gamma * (x^D_i - x^D_j)^2 + epsilon_{ij}

によって与えられる. この効用のもとで学部・生徒は選好を持つ.　ただし生徒に関しては応募資格のある学部のみに応募するようにする.

x^Aはすべての人に望ましいvertical qualityとし, x^Dは場所・位置とみなす. beta, gammaは学部・生徒共通のものとする.
epsilon_{ij} はペア(i, j)に対するidiosyncratic termである.

各生徒の応募数に制限をかけたい時にはmax_candidatesに制限数を渡す. (デフォルト0: 制限なし)

returns s_prefs::Vector{Vector{Int}}, f_prefs::Vector{Vector{Int}}, caps::Vector{Int}

#### get_prefs
```julia
get_prefs(
    faculties::Vector{Faculty},
    students::Vector{Student},
    faculty_utility::Array{Float64, 2},
    student_utility::Array{Float64, 2};
    max_candidates::Int
    )
```

学部, 生徒のutilityを指定して選好表を生成.

returns s_prefs::Vector{Vector{Int}}, f_prefs::Vector{Vector{Int}}, caps::Vector{Int}

#### calc_r_faculty
```julia
calc_r_faculty(f_matched::Vector{Int}, indptr::Vector{Int}, f_prefs::Vector{Vector{Int}})
```

マッチした学部全体について, 選好表におけるマッチ相手の生徒の順位を平均した値を返す.

returns r_faculty::Int

#### calc_r_student
```julia
calc_r_student(s_matched::Vector{Int}, s_prefs::Vector{Vector{Int}})
```

マッチした生徒全員について, 選好表におけるマッチ先の学部の順位を平均した値を返す.

returns r_student::Int

## Usage

1. Clone this repository as a Julia module.
```julia
> Pkg.clone("https://github.com/nswa17/ShingakuMatching")
```

2. Call ShingakuMatching.jl in Julia.

```julia
using ShingakuMatching

faculties = read_faculties()

s_num = 3000 #number of students
students = generate_students(s_num)

s_prefs, f_prefs, caps = get_random_prefs(faculties, students)

s_matched, f_matched, indptr = deferred_acceptance(s_prefs, f_prefs, caps)# call deferred_acceptance algorithm
```

### Reference

[進学振分け準則・進学者受入予定表等 - 総合文化研究科](http://www.c.u-tokyo.ac.jp/zenki/news/kyoumu/file/2014/h27_shinfuritebiki.pdf)
