include("da.jl")

function get_score(mu, sigma2, sigma2_error)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    return mu + sqrt(sigma2 + sigma2_error) * randn()
end

function get_score(distribution, error_distribution)
    #生徒の成績が与えられた分布に従うと仮定.
    #成績には与えられた分布の誤差が混入すると仮定
    return rand(distribution) + rand(error_distribution)
end

type Student
    id::Int
    score::Float64
    score_science::Float64
    score_liberal_arts::Float64
    faculty::Int#所属する科類 文一 => 1, 理一 => 4
    prefs::Array{Int, 1}
end

function generate_students(students_num, distribution, error_distribution, faculty_num; indep = false)
    students_list = Array(Student, students_num)
    id = 1
    for i in 1:students_num
        if indep####Studentsの成績と観測不能な理系・文系への適正が全て独立な場合
            score = get_score(distribution, error_distribution)
            score_science = get_score(distribution, error_distribution)
            score_liberal_arts = get_score(distribution, error_distribution)
            students_list[i] = Student(i, score, score_science, score_liberal_arts, 1, Array(Int, faculty_num+1))#1はとりあえず
        else
            score = get_score(distribution, error_distribution)
            score_science = students_list[i].score(1 + 0.2*(rand() + 0.5))
            score_science = students_list[i].score(1 + 0.2*(rand() + 0.5))
            students_list[i] = Student(i, score, score_science, score_liberal_arts, 1, Array(Int, faculty_num+1))
        end
    end
end

function generate_students(students_num, mu, sigma2, sigma2_error, faculty_num; indep=false)
    students_list = Array(Student, students_num)
    for i in 1:students_num####Studentsの成績と観測不能な理系・文系への適正が全て独立な場合
        if indep
            score = get_score(mu, sigma2, sigma2_error)
            score_science = get_score(mu, sigma2, sigma2_error)
            score_liberal_arts = get_score(mu, sigma2, sigma2_error)
            students_list[i] = Student(i, score, score_science, score_liberal_arts, 1, Array(Int, faculty_num+1))
        else
            score = get_score(mu, sigma2, sigma2_error)
            score_science = get_score(mu, sigma2, sigma2_error)
            score_liberal_arts = get_score(mu, sigma2, sigma2_error)
            students_list[i] = Student(i, score, score_science, score_liberal_arts, 1, Array(Int, faculty_num+1))
        end
    end
    return students_list
end

function get_sorted_students_list(students_list, faculty)#alpha...学部の文系度合い, 学部の理系度合い（それぞれ[0, 1])の値を取る
    return sort(students_list, by=x->x.score+faculty.alpha*x.score_science+faculty.beta*x.score_liberal_arts)
end

type Faculty
    id::Int
    prefs::Array{Int, 1}
    alpha::Float64
    beta::Float64
    cap::Int
end

function generate_faculties(faculty_num, students_num)
    faculties_list = Array(Faculty, faculty_num)
    for i in 1:faculty_num
        faculties_list[i] = Faculty(i, Array(Int, students_num+1), rand(), rand(), 5)#5はキャップ数(とりあえず)
    end
    return faculties_list
end

#get_sorted_students_list = (students_list, faculties_list) -> map(f -> get_sorted_students(students_list, f), faculties_list)

function set_prefs_faculties(faculties_list, students_list)
    for faculty in faculties_list
        sorted_students_list = get_sorted_students_list(students_list, faculty)
        for i in 1:length(students_list)+1
            if i < faculty.cap
                faculty.prefs[i] = sorted_students_list[i].id
            elseif i > faculty.cap
                faculty.prefs[i] = sorted_students_list[i-1].id
            else
                faculty.prefs[i] = 0
            end
        end
    end
end

function set_prefs_students(students_list, faculties_list)#random
    for student in students_list
        student.prefs[1:end-1] = map(f -> f.id, shuffle(faculties_list))
        student.prefs[end] = 0
    end
end

function generate_prefs(as)
    prefs = Array(Int, (length(as[1].prefs), length(as)))
    for i in 1:length(as)
        prefs[:, i] = as[i].prefs
    end
    return prefs
end

function generate_caps(as)
    return Int[a.cap for a in as]
end


#####以下デバッグ用
faculty_num = 2
students_num = 10
mu = 50
sigma2 = 30
sigma2_error = 5

faculties_list = generate_faculties(faculty_num, students_num)
students_list = generate_students(students_num, mu, sigma2, sigma2_error, faculty_num)

set_prefs_faculties(faculties_list, students_list)
set_prefs_students(students_list, faculties_list)
#println(faculties_list)

s_prefs = generate_prefs(students_list)
f_prefs = generate_prefs(faculties_list)
caps = generate_caps(faculties_list)

#println(s_prefs)
println(f_prefs)

s_matched, f_matched, indptr = DA.call_match(s_prefs, f_prefs, caps)

println(s_matched, f_matched)
#sorted_students_list = get_sorted_students_list(students_list, faculties_list)
#println(sorted_students_list)
