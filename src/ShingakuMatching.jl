module ShingakuMatching
    export read_faculties, generate_students, get_random_prefs, get_prefs, calc_r_faculty, calc_r_student

using DataFrames
import Distributions: Uniform, UnivariateDistribution, rand, Logistic

type Student
    id::Int
    current_faculty::Int
end

type Faculty
    id::Int
    cap::Int
    available_for::Vector{Int}
end

function read_faculties(filename=dirname(@__FILE__)*"/../dat/faculties_and_caps_data_2014.csv")
    df = readtable(filename)
    return _generate_faculties(size(df, 1), collect(df[:2]), collect(df[:3]))
end

function _generate_faculties(faculties_num::Int, caps::Vector{Int}, available_for_list::Vector{Vector{Int}})
    faculties = Array(Faculty, faculties_num)
    for i in 1:faculties_num
        if available_for_list[i] == 4# 文1, 2, 3類
            available_for = [1, 2, 3]
        elseif available_for_list[i] == 8# 理1, 2, 3類
            available_for = [5, 6, 7]
        elseif available_for_list[i] == 9# 文理1, 2, 3類
            available_for = [1, 2, 3, 5, 6, 7]
        else
            available_for = [available_for_list[i]]
        end
        faculties[i] = Faculty(i, caps[i], available_for)
    end
    return faculties
end

function generate_students(students_num::Int, current_faculties=rand([1, 2, 3, 5, 6, 7], students_num))
    students = Array(Student, students_num)
    for (i, current_faculty) in enumerate(current_faculties)
        students[i] = Student(i, current_faculty)
    end
    return students
end

function utility_factory(beta::Float64, gamma::Float64, target_vertical_quality_list::Vector{Int}, relative_quality_list::Vector{Int}, target_relative_quality_list::Vector{Int}, error_dist::UnivariateDistribution)
    return function(id, target_id)
        return beta * target_vertical_quality_list[target_id] - gamma * (relative_quality_list[id] - relative_quality_list[target_id])^2 + rand(error_dist)
    end
end

function get_random_prefs(
    faculties::Vector{Faculty},
    students::Vector{Student};
    beta::Float64=0.7,
    gamma::Float64=0.2,
    faculty_vertical_dist::UnivariateDistribution=Uniform(0, 1),
    student_vertical_dist::UnivariateDistribution=Uniform(0, 1),
    faculty_relative_dist::UnivariateDistribution=Uniform(0, 1),
    student_relative_dist::UnivariateDistribution=Uniform(0, 1),
    error_dist::UnivariateDistribution=Logistic(),
    seed::Int=0,
    max_candidates::Int=0
    )
    srand(seed)
    num_f = length(faculties)
    num_s = length(students)
    faculty_vertical_quality_list = rand(faculty_vertical_dist, num_f)
    student_vertical_quality_list = rand(student_vertical_dist, num_s)
    faculty_relative_quality_list = rand(faculty_relative_dist, num_f)
    student_relative_quality_list = rand(student_relative_dist, num_s)

    s_utility = utility_factory(beta, gamma, faculty_vertical_quality_list, student_relative_quality_list, faculty_relative_quality_list, error_dist)
    f_utility = utility_factory(beta, gamma, student_vertical_quality_list, faculty_relative_quality_list, student_relative_quality_list, error_dist)

    faculty_utility = Array(Float64, num_s, num_f)
    student_utility = Array(Float64, num_f, num_s)
    for f_id in 1:num_f
        for s_id in 1:num_s
            faculty_utility[s_id, f_id] = f_utility(f_id, s_id)
            student_utility[f_id, s_id] = s_utility(s_id, f_id)
        end
    end

    return get_prefs(faculties, students, faculty_utility, student_utility, max_candidates=max_candidates)
end

function get_prefs(
    faculties::Vector{Faculty},
    students::Vector{Student},
    faculty_utility::Array{Float64, 2},
    student_utility::Array{Float64, 2};
    max_candidates::Int=0
    )
    num_f = length(faculties)
    num_s = length(students)

    caps::Vector{Int} = collect(map(f -> f.cap == 0 ? num_s : f.cap, faculties))
    s_prefs = Vector{Int}[]
    f_prefs = Vector{Int}[]

    for s_id in 1:num_s
        raw_s_pref = sort(1:num_f, by=f_id -> student_utility[f_id, s_id], rev=true)
        s_pref = filter(f_id -> students[s_id].current_faculty in faculties[f_id].available_for, raw_s_pref)

        push!(s_prefs, max_candidates > 0 ? collect(take(s_pref, max_candidates)) : s_pref)
    end

    for f_id in 1:num_f
        raw_f_pref = sort(1:num_s, by=s_id -> faculty_utility[s_id, f_id], rev=true)
        f_pref = filter(s_id -> students[s_id].current_faculty in faculties[f_id].available_for, raw_f_pref)

        push!(f_prefs, collect(f_pref))
    end

    return s_prefs, f_prefs, caps
end

function calc_r_faculty(f_matched::Vector{Int}, indptr::Vector{Int}, f_prefs::Vector{Vector{Int}})
    matched_num = 0
    sum_rank = 0
    for f_id in 1:length(indptr)-1
        for ind in indptr[f_id]:indptr[f_id+1]-1
            s_id = f_matched[ind]
            s_id == 0 && break
            matched_num += 1
            sum_rank += findfirst(f_prefs[f_id], s_id)
        end
    end
    return matched_num != 0 ? sum_rank / matched_num : 0
end

function calc_r_student(s_matched::Vector{Int}, s_prefs::Vector{Vector{Int}})
    matched_num = 0
    sum_rank = 0
    for (s_id, f_id) in enumerate(s_matched)
        if f_id != 0
            matched_num += 1
            sum_rank += findfirst(s_prefs[s_id], f_id)
        end
    end
    return matched_num != 0 ? sum_rank / matched_num : 0
end

end
