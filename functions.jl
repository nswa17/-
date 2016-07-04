include("da.jl")
#Todo: comparison b/w da matching and normal matching
#Todo: comparison of alphas
#Todo: how many unmatched?
#Todo: compare these results and test
#Todo: 生徒の分布に対してrobust?
#Todo: cap on num of fac stu apply to
#Todo: 上の数字を変えていくと...?
#Todo: Stu vs Faculty proposing

type Student
    id::Int
    level::Float64#0.0~1.0に変換すると使いやすい?
    preference::Float64
    current_faculty::Int#所属する科類 文一 => 1, 理一 => 4
    prefs::Array{Int, 1}
    preference_first::Float64#0.0~1.0 どれくらい自分の選考を成績よりも重視するか
end

type Faculty
    name::AbstractString
    id::Int
    prefs::Array{Int, 1}
    preference::Float64
    level::Float64
    cap::Int
    available_for::Array{Int, 1}#その類の人のみがfacultyに応募できる.
end

function get_level(mu, sigma2, sigma2_error)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    return mu + sqrt(sigma2 + sigma2_error) * randn()
end

function get_level(distribution, error_distribution)
    #生徒の成績が与えられた分布に従うと仮定.
    #成績には与えられた分布の誤差が混入すると仮定
    return rand(distribution) + rand(error_distribution)
end

function generate_students(students_num, distribution, error_distribution, faculty_num)
    students_list = Array(Student, students_num)
    id = 1
    for i in 1:students_num
        level = get_level(distribution, error_distribution)
        preference = get_level(distribution, error_distribution)
        students_list[i] = Student(i, level, preference, rand(1:6), Array(Int, faculty_num+1), 0.5)#0.5は適当
    end
    return students_list
end

function generate_students(students_num, mu, sigma2, sigma2_error, faculty_num)
    students_list = Array(Student, students_num)
    for i in 1:students_num
        level = get_level(mu, sigma2, sigma2_error)
        preference = get_level(mu, sigma2, sigma2_error)
        students_list[i] = Student(i, level, preference, rand(1:6), Array(Int, faculty_num+1), 0.5)
    end
    return students_list
end

function get_sorted_faculties_id_list(faculties_list, student, sort_func)
    available_faculties_list = filter(f -> in(student.current_faculty, f.available_for), faculties_list)
    sorted_faculties_id_list = Array(Int, length(faculties_list)+1)
    sorted_faculties_id_list[1:length(available_faculties_list)] = map(f -> f.id, sort(available_faculties_list, by = f -> sort_func(student, f)))#sort関数は適当
    sorted_faculties_id_list[length(available_faculties_list) + 1] = 0
    #println(length())
    sorted_faculties_id_list[(length(available_faculties_list) + 2):end] = map(f -> f.id, filter(f -> !in(f, available_faculties_list), faculties_list))
    return sorted_faculties_id_list
end

function generate_faculties(faculty_num, students_num)
    faculties_list = Array(Faculty, faculty_num)
    for i in 1:faculty_num
        faculties_list[i] = Faculty(string(i), i, Array(Int, students_num+1), rand(), rand(), students_num-1, [rand(1:6)])#students_num-1はキャップ数(とりあえず)
    end#id, prefs, preference, level, cap, available_for
    return faculties_list
end

function generate_faculties(faculty_names, caps, available_for, students_num)
    faculties_list = Array(Faculty, length(faculty_names))
    for i in 1:length(faculty_names)
        faculties_list[i] = Faculty(faculty_names[i], i, Array(Int, students_num+1), rand(), rand(), caps[i], [available_for[i]])#students_num-1はキャップ数(とりあえず)
    end#id, prefs, preference, level, cap, available_for
    return faculties_list
end

function generate_faculties(preference_list, level_list, cap_list, available_for_list, students_num)
    faculties_list = Array(Faculty, preference_list)
    for i in 1:length(preference_list)
        faculties_list[i] = Faculty(string(i), i, Array(Int, students_num+1), preference_list[i], level_list[i], cap_list[i], available_for_list[i])
    end
end
#get_sorted_students_list = (students_list, faculties_list) -> map(f -> get_sorted_students(students_list, f), faculties_list)

function set_prefs_faculties(faculties_list, students_list)
    for faculty in faculties_list
        sorted_students_list = sort(students_list, by = s -> s.level)
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

function set_prefs_students(students_list, faculties_list)
    for student in students_list
        sort_func = (student, faculty) -> -student.preference_first*abs(faculty.preference-student.preference)-(1-student.preference_first)*abs(faculty.level-student.level)
        student.prefs = get_sorted_faculties_id_list(faculties_list, student, sort_func)
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

function evaluate_matched(s_matched, s_prefs)#min:1 the lower the better
    return sum([findfirst(s_prefs[:, i], r) for (i, r) in enumerate(s_matched)])/size(s_prefs, 2)
end

function evaluate_matched2(s_matched, s_prefs)#min:1
    return sqrt(sum([findfirst(s_prefs[:, i], r)^2 for (i, r) in enumerate(s_matched)])/size(s_prefs, 2))
end

function evaluate_matched3(s_matched, s_prefs)#min:1
    return 2 + sum([(findfirst(s_prefs[:, i], r) == 0 ? 0 : -1/findfirst(s_prefs[:, i], r)) for (i, r) in enumerate(s_matched)])/size(s_prefs, 2)
end


function evaluate_matched4(s_matched, s_prefs)#min:1
    return 1 + sum([log(findfirst(s_prefs[:, i], r)) for (i, r) in enumerate(s_matched)])/size(s_prefs, 2)
end

function easy_matching(); end

function read_faculty_data(filename, students_num)
    df = readtable("revised.csv")
    return generate_faculties(df[:1], df[:2], df[:3], students_num)
end

#####以下デバッグ用
faculty_num = 4
students_num = 10
mu = 0.5
sigma2 = 0.2
sigma2_error = 0.05

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
println(evaluate_matched(s_matched, s_prefs))
println(evaluate_matched2(s_matched, s_prefs))
println(evaluate_matched3(s_matched, s_prefs))
#sorted_students_list = get_sorted_students_list(students_list, faculties_list)
#println(sorted_students_list)
