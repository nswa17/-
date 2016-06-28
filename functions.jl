include("da.jl")
#自分の好きなところに成績に関係なく応募すると仮定

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
    characteristic::Float64
    faculty::Int#所属する科類 文一 => 1, 理一 => 4
    prefs::Array{Int, 1}
end

function generate_students(students_num, distribution, error_distribution, faculty_num)
    students_list = Array(Student, students_num)
    id = 1
    for i in 1:students_num
        score = get_score(distribution, error_distribution)
        score_sub = get_score(distribution, error_distribution)
        students_list[i] = Student(i, score, score_sub, 1, Array(Int, faculty_num+1))#1はとりあえず
    end
    return students_list
end

function generate_students(students_num, mu, sigma2, sigma2_error, faculty_num)
    students_list = Array(Student, students_num)
    for i in 1:students_num
        score = get_score(mu, sigma2, sigma2_error)
        characteristic = get_score(mu, sigma2, sigma2_error)
        students_list[i] = Student(i, score, characteristic, 1, Array(Int, faculty_num+1))
    end
    return students_list
end

function get_sorted_faculties_id_list(faculties_list, student)#alpha...学部の文系度合い, 学部の理系度合い（それぞれ[0, 1])の値を取る
    available_faculties_list = shuffle(faculties_list)[1:rand(1:length(faculties_list))]#Todo: 自分が応募できるfacultyのみに手が出せるようにする予定
    sorted_faculties_id_list = zeros(Int, length(faculties_list)+1)
    sorted_faculties_id_list[1:length(available_faculties_list)] = map(f -> f.id, sort(available_faculties_list, by = f -> -abs(f.characteristic-student.characteristic)))#sort関数は適当
    return sorted_faculties_id_list
end

type Faculty
    id::Int
    prefs::Array{Int, 1}
    characteristic::Float64
    level::Float64
    cap::Int
end

function generate_faculties(faculty_num, students_num)
    faculties_list = Array(Faculty, faculty_num)
    for i in 1:faculty_num
        faculties_list[i] = Faculty(i, Array(Int, students_num+1), rand(), rand(), students_num-2)#students_num-2はキャップ数(とりあえず)
    end
    return faculties_list
end

#get_sorted_students_list = (students_list, faculties_list) -> map(f -> get_sorted_students(students_list, f), faculties_list)

function set_prefs_faculties(faculties_list, students_list)
    for faculty in faculties_list
        sorted_students_list = sort(students_list, by = s -> s.score)
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
        student.prefs = get_sorted_faculties_id_list(faculties_list, student)
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

function evaluate_matched(s_matched, s_prefs)
    return sum([findfirst(s_prefs[:, i], r) for (i, r) in enumerate(s_matched)])/size(s_prefs, 2)
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
#println(f_prefs)

s_matched, f_matched, indptr = DA.call_match(s_prefs, f_prefs, caps)

println(s_matched, f_matched)
#sorted_students_list = get_sorted_students_list(students_list, faculties_list)
#println(sorted_students_list)
