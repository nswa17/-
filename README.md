# ShingakuMatching.jl
tools for simulating 東大第二段階進学選択 in Julia 0.6.

実際の第二段階定数データを読み込む関数や, Random Utility Modelの下でのpreferenceを返す関数などを提供.

## Docs

### Structs

#### Department
```julia
struct Department
    cap::Int#募集人数
    lower_streams::Vector{Int}#その類の人のみがDepartmentに応募できる.
end
```

#### Student
```julia
struct Student
    stream::Int#所属する科類 文一 => 1, 理一 => 5
end
```

### Functions

#### get_departments
```julia
get_departments{T <: AbstractString}([filename::T])
```

第二段階定数データの取り込み.

returns `departments::Vector{Department}`

#### get_students
```julia
get_students(num_students::Int[, streams::Vector{Int}])
```

streamsは科類の配列. ただし文科1,2,3類は1, 2, 3、理科1,2,3類は5, 6, 7で表す.

第二引数未設定の場合科類をランダムに(各科類の割合が一様になるように)割り当てる.

returns `students::Vector{Student}`

#### get_random_prefs
```julia
get_random_prefs(
    students::Vector{Student},
    departments::Vector{Department}
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

UnivariateDistributionは[Distributions.jl](http://distributionsjl.readthedocs.io/en/latest/)で定義されるUnivariateDistributionを意味する.

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
    students::Vector{Student},
    departments::Vector{Department},
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

マッチした学部全体について, それぞれの持つ選好表におけるマッチ相手の生徒の順位を平均した値を返す.

returns `r_department::Float64`

#### calc_r_student
```julia
calc_r_student(s_matched::Vector{Int}, s_prefs::Vector{Vector{Int}})
```

マッチした生徒全員について, それぞれの持つ選好表におけるマッチ先の学部の順位を平均した値を返す.

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

departments = get_departments()

num_students = 300 #number of students
students = get_students(num_students)

s_prefs, d_prefs, caps = get_random_prefs(students, departments)
```

4. Use your own implementation of (many-to-one) deferred acceptance algorithm.

```julia
s_matched, d_matched, indptr = deferred_acceptance(s_prefs, d_prefs, caps)
```

## Reference

[進学振分け準則・進学者受入予定表等 - 総合文化研究科](http://www.c.u-tokyo.ac.jp/zenki/news/kyoumu/file/2014/h27_shinfuritebiki.pdf)
