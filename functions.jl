include("da.jl")
#Todo: comparison b/w da matching and normal matching
#Todo: how many unmatched?
#Todo: compare these results and test
#Todo: 生徒の分布に対してrobust?
#Todo: cap on num of fac stu apply to
#Todo: 上の数字を変えていくと...?
#Todo: Stu proposing vs Faculty proposing

type Student
    id::Int
    level::Float64#0.0~1.0に変換すると使いやすい?
    preference::Float64
    current_faculty::Int#所属する科類 文一 => 1, 理一 => 4
    prefs::Array{Int, 1}
    real_prefs::Array{Int, 1}
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

function get_01(mu, sigma2, sigma2_error)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    return mu + sqrt(sigma2 + sigma2_error) * randn()
end

function get_01(distribution, error_distribution)
    #生徒の成績が与えられた分布に従うと仮定.
    #成績には与えられた分布の誤差が混入すると仮定
    return rand(distribution) + rand(error_distribution)
end

function generate_students(students_num, distribution, error_distribution, faculty_num, preference_func)
    students_list = Array(Student, students_num)
    id = 1
    for i in 1:students_num
        level = get_01(distribution, error_distribution)
        preference = get_01(distribution, error_distribution)
        students_list[i] = Student(i, level, preference, rand(1:6), Array(Int, faculty_num+1), Array(Int, faculty_num+1), preference_func())#0.5は適当
    end
    return students_list
end

function generate_students(students_num, mu, sigma2, sigma2_error, faculty_num, preference_func)
    students_list = Array(Student, students_num)
    for i in 1:students_num
        level = get_01(mu, sigma2, sigma2_error)
        preference = get_01(mu, sigma2, sigma2_error)
        students_list[i] = Student(i, level, preference, rand(1:6), Array(Int, faculty_num+1), Array(Int, faculty_num+1), preference_func())
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

function generate_faculties(ids, faculty_names, caps, available_for_list, students_num)
    faculties_list = Array(Faculty, length(faculty_names))
    for i in 1:length(faculty_names)
        if available_for_list[i] == 4
            available_for = [1, 2, 3]
        elseif available_for_list[i] == 8
            available_for = [5, 6, 7]
        elseif available_for_list[i] == 9
            available_for = [1, 2, 3, 5, 6, 7]
        else
            available_for = [available_for_list[i]]
        end
        faculties_list[i] = Faculty(faculty_names[i], ids[i], Array(Int, students_num+1), rand(), rand(), caps[i], available_for)#students_num-1はキャップ数(とりあえず)
    end#id, prefs, preference, level, cap, available_for
    return faculties_list
end
"""
function generate_faculties(preference_list, level_list, cap_list, available_for_list, students_num)
    faculties_list = Array(Faculty, preference_list)
    for i in 1:length(preference_list)
        faculties_list[i] = Faculty(string(i), i, Array(Int, students_num+1), preference_list[i], level_list[i], cap_list[i], available_for_list[i])
    end
end

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
"""

function set_prefs_faculties(faculties_list, students_list)
    for faculty in faculties_list
        sorted_students_list = sort(students_list, by = s -> s.level)
        faculty.prefs[1:end-1] = map(s -> s.id, sorted_students_list)
        faculty.prefs[end] = 0
    end
end

function set_prefs_students(students_list, faculties_list)
    for student in students_list
        sort_func = (student, faculty) -> -student.preference_first*abs(faculty.preference-student.preference)-(1-student.preference_first)*abs(faculty.level-student.level)
        student.prefs = get_sorted_faculties_id_list(faculties_list, student, sort_func)
    end
end

function set_real_prefs_students(students_list, faculties_list)
    for student in students_list
        sort_func = (student, faculty) -> -abs(faculty.preference-student.preference)
        student.real_prefs = get_sorted_faculties_id_list(faculties_list, student, sort_func)
    end
end

function generate_prefs(as)
    prefs = Array(Int, (length(as[1].prefs), length(as)))
    for i in 1:length(as)
        prefs[:, i] = as[i].prefs
    end
    return prefs
end

function get_real_prefs(as)
    prefs = Array(Int, (length(as[1].real_prefs), length(as)))
    for i in 1:length(as)
        prefs[:, i] = as[i].real_prefs
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

function evaluate_matched5(s_matched, s_prefs)
    return 1 + sum([r == 0 for (i, r) in enumerate(s_matched)])/length(s_matched)
end

function easy_matching(students_list, caps)
    s_prefs = generate_prefs(students_list)
    student_num = size(s_prefs, 2)
    students_challenge = trues(student_num)
    faculty_num = length(caps)

    f_matched = zeros(Int, sum(caps))
    f_vacants = copy(caps)
    s_matched = zeros(Int, students_num)
    indptr = Array(Int, faculty_num+1)
    i::Int = 0
    indptr[1] = 1
    for i in 1:faculty_num
        indptr[i+1] = indptr[i] + caps[i]
    end

    for stage in 1:faculty_num
        applying_students = []
        for s in students_list
            if s_prefs[stage, s.id] == 0
                students_challenge[s.id] = false
            elseif students_challenge[s.id] == true
                push!(applying_students, s)
            end
        end
        for j in 1:faculty_num
            faculty_applying_students = filter(s -> s.prefs[stage] == j, applying_students)
            sort(faculty_applying_students, by=s -> s.level, rev=true)
            for s in faculty_applying_students
                if f_vacants[j] > 0
                    f_matched[indptr[j] + caps[j] - f_vacants[j]] = s.id
                    s_matched[s.id] = j
                    students_challenge[s.id] = false
                    f_vacants[j] -= 1
                end
            end
        end
    end
    return s_matched, f_matched, indptr
end

function read_faculty_data(filename, student_num)
    df = readtable("revised.csv")
    return generate_faculties(df[:1], df[:2], df[:3], df[:4], student_num)
end
