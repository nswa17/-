module ShingakuMatching
    export get_departments, get_students, get_random_prefs,
           get_prefs, calc_r_department, calc_r_student

using DataFrames
import Distributions: Uniform, UnivariateDistribution, rand, Logistic

struct Student
    id::Int
    stream::Int
end

struct Department
    id::Int
    cap::Int
    lower_streams::Vector{Int}
end

function get_departments(filename=dirname(@__FILE__)*"/../dat/departments_and_caps_data_2014.csv")
    df = readtable(filename)
    return _generate_departments(size(df, 1), collect(df[:2]), collect(df[:3]))
end

function _generate_departments(num_deps::Int, caps::Vector{Int}, lower_stream_list::Vector{Int})
    departments = Array{Department}(num_deps)
    for i in 1:num_deps
        if lower_stream_list[i] == 4# 文1, 2, 3類
            lower_streams = [1, 2, 3]
        elseif lower_stream_list[i] == 8# 理1, 2, 3類
            lower_streams = [5, 6, 7]
        elseif lower_stream_list[i] == 9# 文理1, 2, 3類
            lower_streams = [1, 2, 3, 5, 6, 7]
        else
            lower_streams = [lower_stream_list[i]]
        end
        departments[i] = Department(i, caps[i], lower_streams)
    end
    return departments
end

function get_students(num_studs::Int,
                           streams::Vector{Int}=rand([1, 2, 3, 5, 6, 7], num_studs))
    students = Array{Student}(num_studs)
    for (i, stream) in enumerate(streams)
        students[i] = Student(i, stream)
    end
    return students
end

function utility_factory(beta::Float64,
                         gamma::Float64,
                         target_vertical_quality_list::Vector{Float64},
                         relative_quality_list::Vector{Float64},
                         target_relative_quality_list::Vector{Float64},
                         error_dist::UnivariateDistribution)
    return function(id, target_id)
        return beta * target_vertical_quality_list[target_id] -
               gamma * (relative_quality_list[id] - target_relative_quality_list[target_id])^2 +
               rand(error_dist)
    end
end

function get_random_prefs(departments::Vector{Department},
                          students::Vector{Student};
                          beta::Float64=0.7,
                          gamma::Float64=0.2,
                          department_vertical_dist::UnivariateDistribution=Uniform(0, 1),
                          student_vertical_dist::UnivariateDistribution=Uniform(0, 1),
                          department_relative_dist::UnivariateDistribution=Uniform(0, 1),
                          student_relative_dist::UnivariateDistribution=Uniform(0, 1),
                          error_dist::UnivariateDistribution=Logistic(),
                          seed::Int=0,
                          max_applications::Int=0)
    srand(seed)
    num_deps = length(departments)
    num_studs = length(students)
    department_vertical_quality_list = rand(department_vertical_dist, num_deps)
    student_vertical_quality_list = rand(student_vertical_dist, num_studs)
    department_relative_quality_list = rand(department_relative_dist, num_deps)
    student_relative_quality_list = rand(student_relative_dist, num_studs)

    s_utility = utility_factory(beta, gamma, department_vertical_quality_list,
                                student_relative_quality_list, department_relative_quality_list, error_dist)
    d_utility = utility_factory(beta, gamma, student_vertical_quality_list,
                                department_relative_quality_list, student_relative_quality_list, error_dist)

    department_utility = Array{Float64}(num_studs, num_deps)
    student_utility = Array{Float64}(num_deps, num_studs)
    for d_id in 1:num_deps
        for s_id in 1:num_studs
            department_utility[s_id, d_id] = d_utility(d_id, s_id)
            student_utility[d_id, s_id] = s_utility(s_id, d_id)
        end
    end

    return get_prefs(departments, students, department_utility,
                     student_utility, max_applications=max_applications)
end

function get_prefs(departments::Vector{Department},
                   students::Vector{Student},
                   department_utility::Array{Float64, 2},
                   student_utility::Array{Float64, 2};
                   max_applications::Int=0)

    num_deps = length(departments)
    num_studs = length(students)

    caps::Vector{Int} = collect(map(f -> f.cap == 0 ? num_studs : f.cap, departments))
    s_prefs = Vector{Int}[]
    d_prefs = Vector{Int}[]

    for s_id in 1:num_studs
        raw_s_pref = sort(1:num_deps, by=d_id -> student_utility[d_id, s_id], rev=true)
        s_pref = filter(d_id -> students[s_id].stream in departments[d_id].lower_streams, raw_s_pref)

        push!(s_prefs, max_applications > 0 ? collect(Iterators.take(s_pref, max_applications)) : s_pref)
    end

    for d_id in 1:num_deps
        raw_d_pref = sort(1:num_studs, by=s_id -> department_utility[s_id, d_id], rev=true)
        d_pref = filter(s_id -> students[s_id].stream in departments[d_id].lower_streams, raw_d_pref)

        push!(d_prefs, collect(d_pref))
    end

    return s_prefs, d_prefs, caps
end

function calc_r_department(d_matched::Vector{Int}, indptr::Vector{Int}, d_prefs::Vector{Vector{Int}})
    num_matched = length(d_matched)
    sum_rank = 0
    for d_id in 1:length(indptr)-1
        for ind in indptr[d_id]:indptr[d_id+1]-1
            s_id = d_matched[ind]
            sum_rank += findfirst(d_prefs[d_id], s_id)
        end
    end
    return num_matched != 0 ? sum_rank / num_matched : 0
end

function calc_r_student(s_matched::Vector{Int}, s_prefs::Vector{Vector{Int}})
    num_matched = 0
    sum_rank = 0
    for (s_id, d_id) in enumerate(s_matched)
        if d_id != 0
            num_matched += 1
            sum_rank += findfirst(s_prefs[s_id], d_id)
        end
    end
    return num_matched != 0 ? sum_rank / num_matched : 0
end

end
