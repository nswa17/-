# ShingakuMatching.jl
tools for simulating 東大第二段階進学選択 in Julia.

実際の第二段階定数データを読み込み, Random Utility Modelの下でのpreferenceを返す関数を提供します.

## Docs

### Types

#### Department
```julia
type Department
    id::Int
    cap::Int#募集人数
    lower_streams::Vector{Int}#その類の人のみがDepartmentに応募できる.
end
```

#### Student
```julia
type Student
    id::Int
    stream::Int#所属する科類 文一 => 1, 理一 => 4
end
```

### Functions

#### read_data
```julia
read_data{T <: AbstractString}([filename::T])
```

第二段階定数データの取り込み.

returns `departments::Vector{Department}`

#### generate_students
```julia
generate_students(students_num::Int[, streams::Vector{Int}])
```

第二引数未設定の場合科類をランダムに割り当てる.

returns `students::Vector{Student}`

#### get_random_prefs
```julia
get_random_prefs(
    departments::Vector{Department},
    students::Vector{Student}
    [;beta::Float64,
    gamma::Float64,
    department_vertical_dist::UnivariateDistribution,
    student_vertical_dist::UnivariateDistribution,
    department_relative_dist::UnivariateDistribution,
    student_relative_dist::UnivariateDistribution,
    error_dist::UnivariateDistribution,
    seed::Int,
    max_applications::Int]
    )
```

Random Utility Model(Hitsch et al. (2010))の下でpreferenceをランダムに生成.

具体的には, 全アクターが２つのcharacteristics, x^A and x^Dをもち, iがjとマッチする事による効用は,

u_i(j) = beta * x^A_j - gamma * (x^D_i - x^D_j)^2 + epsilon_{ij}

によって与えられる. この効用のもとで学部・生徒は選好を持つ.　ただし生徒に関しては応募資格のある学部のみに応募するようにする.

x^Aはすべての人に望ましいvertical qualityとし, x^Dは場所・位置とみなす. beta, gammaは学部・生徒共通のものとする.
epsilon_{ij} はペア(i, j)に対するidiosyncratic termである.

各生徒の応募数に制限をかけたい時にはmax_applicationsに制限数を渡す. (デフォルト0: 制限なし)

returns `s_prefs::Vector{Vector{Int}}, d_prefs::Vector{Vector{Int}}, caps::Vector{Int}`

#### get_prefs
```julia
get_prefs(
    departments::Vector{Department},
    students::Vector{Student},
    department_utility::Array{Float64, 2},
    student_utility::Array{Float64, 2}
    [;max_applications::Int]
    )
```

学部, 生徒のutilityを指定して選好表を生成.

returns `s_prefs::Vector{Vector{Int}}, d_prefs::Vector{Vector{Int}}, caps::Vector{Int}`

#### calc_r_department
```julia
calc_r_department(d_matched::Vector{Int}, indptr::Vector{Int}, d_prefs::Vector{Vector{Int}})
```

マッチした学部全体について, 選好表におけるマッチ相手の生徒の順位を平均した値を返す.

returns `r_department::Float64`

#### calc_r_student
```julia
calc_r_student(s_matched::Vector{Int}, s_prefs::Vector{Vector{Int}})
```

マッチした生徒全員について, 選好表におけるマッチ先の学部の順位を平均した値を返す.

returns `r_student::Float64`

## Usage

1. Clone this repository in Julia.
```julia
Pkg.clone("https://github.com/nswa17/ShingakuMatching")
```

2. Run tests.
```julia
Pkg.test("ShingakuMatching")
```

3. Call ShingakuMatching.jl in Julia.

```julia
using ShingakuMatching

departments = read_data()

s_num = 3000 #number of students
students = generate_students(s_num)

s_prefs, d_prefs, caps = get_random_prefs(departments, students)
```

## Reference

[進学振分け準則・進学者受入予定表等 - 総合文化研究科](http://www.c.u-tokyo.ac.jp/zenki/news/kyoumu/file/2014/h27_shinfuritebiki.pdf)
