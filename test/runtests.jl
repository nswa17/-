using Base.Test
using ShingakuMatching
import Distributions: Bernoulli

@testset "Testing ShingakuMatching.jl" begin
    departments = read_data()
    @testset "read_data" begin
        @test length(departments) == 151
        @testset "_generate_data" begin
            generated_deps = ShingakuMatching._generate_departments(4, ones(Int, 4), [1, 9, 4, 8])
            lower_streams_list = [[1], [1, 2, 3, 5, 6, 7], [1, 2, 3], [5, 6, 7]]
            for (generated_dep, lower_streams) in zip(generated_deps, lower_streams_list)
                @test generated_dep.lower_streams == lower_streams
            end
        end
    end
    @testset "generate_students" begin
        s_num = 6
        s_streams = [1, 2, 3, 5, 6, 7]
        students = generate_students(s_num, s_streams)
        for s_id in 1:s_num
            @test students[s_id].id == s_id
            @test students[s_id].stream == s_streams[s_id]
        end
    end
    @testset "utility_factory" begin
        beta = 1.0
        gamma = 1.0
        department_relative_quality_list = [1.0, 0.0]
        student_relative_quality_list = [1.0, 0.0]
        department_vertical_quality_list = [0.7, 0.4]
        student_vertical_quality_list = [0.5, 0.6]
        error_dist = Bernoulli(0)

        s_utility = ShingakuMatching.utility_factory(beta, gamma, department_vertical_quality_list, student_relative_quality_list, department_relative_quality_list, error_dist)
        d_utility = ShingakuMatching.utility_factory(beta, gamma, student_vertical_quality_list, department_relative_quality_list, student_relative_quality_list, error_dist)
        @test s_utility(1, 1) == 0.7
        @test s_utility(1, 2) == 0.4 - 1
        @test s_utility(2, 1) == 0.7 - 1
        @test s_utility(2, 2) == 0.4
        @test d_utility(1, 1) == 0.5
        @test d_utility(1, 2) == 0.6 - 1
        @test d_utility(2, 1) == 0.5 - 1
        @test d_utility(2, 2) == 0.6
    end
    s_num = 2
    d_num = 2
    departments = [ShingakuMatching.Department(i, 0, [1, 2, 3, 5, 6, 7]) for i in 1:s_num]
    departments_capped = [ShingakuMatching.Department(i, 1, [1, 2, 3, 5, 6, 7]) for i in 1:s_num]
    departments_restricted = [ShingakuMatching.Department(i, 0, [7]) for i in 1:s_num]
    students = [ShingakuMatching.Student(i, rand([1, 2, 3, 5, 6])) for i in 1:d_num]
    department_utility = [0.5 -0.5; -0.4 0.6]
    student_utility = [0.7 -0.3; -0.6 0.4]
    @testset "get_prefs" begin
        @testset "without caps" begin
            s_prefs, d_prefs, caps = get_prefs(departments, students, department_utility, student_utility)

            @test s_prefs == [[1, 2], [2, 1]]
            @test d_prefs == [[1, 2], [2, 1]]
            @test caps == fill(s_num, d_num)
        end
        @testset "with caps" begin
            s_prefs, d_prefs, caps = get_prefs(departments_capped, students, department_utility, student_utility)

            @test s_prefs == [[1, 2], [2, 1]]
            @test d_prefs == [[1, 2], [2, 1]]
            @test caps == ones(Int, d_num)
        end
        @testset "with caps" begin
            s_prefs, d_prefs, caps = get_prefs(departments_restricted, students, department_utility, student_utility)

            @test s_prefs == [[], []]
            @test d_prefs == [[], []]
            @test caps == fill(s_num, d_num)
        end
    end
    s_matched = [1, 2]
    s_prefs = [[2, 1], [2, 1]]
    d_matched = [1, 2]
    indptr = [2, 3]
    d_prefs = [[1, 2], [2, 1]]
    @testset "calc_r_department" begin
        @test calc_r_department(d_matched, indptr, d_prefs) == 1.
    end
    @testset "calc_r_student" begin
        @test calc_r_student(s_matched, s_prefs) == 1.5
    end
end
