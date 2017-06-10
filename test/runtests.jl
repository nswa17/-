using Base.Test
using ShingakuMatching

@testset "Testing ShingakuMatching.jl" begin
    faculties = read_faculties()
    @testset "read_faculties" begin
        @test length(faculties) == 151
        @testset "_generate_faculties" begin
            generated_facs = ShingakuMatching._generate_faculties(4, ones(Int, 4), [[1, 2], [9], [4], [8]])
            available_for_list = [[1, 2], [1, 2, 3, 5, 6, 7], [1, 2, 3], [5, 6, 7]]
            for (generated_fac, available_for) in zip(generated_facs, available_for_list)
                @test generated_fac.available_for == available_for
            end
        end
    end
    @testset "generate_students" begin
        s_num = 6
        s_current_facs = [1, 2, 3, 5, 6, 7]
        students = generate_students(s_num, s_current_facs)
        for s_id in 1:s_num
            @test students[s_id].id == s_id
            @test students[s_id].current_faculty == s_current_facs[s_id]
        end
    end
    @testset "utility_factory" begin
        beta = 1.0
        gamma = 1.0
        faculty_relative_quality_list = [1.0, 0.0]
        student_relative_quality_list = [1.0, 0.0]
        faculty_vertical_quality_list = [0.7, 0.4]
        student_vertical_quality_list = [0.5, 0.6]
        error_dist = 0:0

        s_utility = utility_factory(beta, gamma, faculty_vertical_quality_list, student_relative_quality_list, faculty_relative_quality_list, error_dist)
        f_utility = utility_factory(beta, gamma, student_vertical_quality_list, faculty_relative_quality_list, student_relative_quality_list, error_dist)
        @test s_utility(1, 1) == 0.7
        @test s_utility(1, 2) == 0.4 - 1
        @test s_utility(2, 1) == 0.7 - 1
        @test s_utility(2, 2) == 0.4
        @test f_utility(1, 1) == 0.5
        @test f_utility(1, 2) == 0.6 - 1
        @test f_utility(2, 1) == 0.5 - 1
        @test f_utility(2, 2) == 0.6
    end
    s_num = 2
    f_num = 2
    faculties = [ShingakuMatching.Faculty(i, 0, [1, 2, 3, 5, 6, 7]) for i in 1:s_num]
    faculties_capped = [ShingakuMatching.Faculty(i, 1, [1, 2, 3, 5, 6, 7]) for i in 1:s_num]
    faculties_restricted = [ShingakuMatching.Faculty(i, 0, [7]) for i in 1:s_num]
    students = [ShingakuMatching.Student(i, rand([1, 2, 3, 5, 6])) for i in 1:f_num]
    faculty_utility = [0.5 -0.5; -0.4 0.6]
    student_utility = [0.7 -0.3; -0.6 0.4]
    @testset "get_prefs" begin
        @testset "without caps" begin
            s_prefs, f_prefs, caps = get_prefs(faculties, students, faculty_utility, student_utility)

            @test s_prefs == [[1, 2], [2, 1]]
            @test f_prefs == [[1, 2], [2, 1]]
            @test caps == fill(s_num, f_num)
        end
        @testset "with caps" begin
            s_prefs, f_prefs, caps = get_prefs(faculties_capped, students, faculty_utility, student_utility)

            @test s_prefs == [[1, 2], [2, 1]]
            @test f_prefs == [[1], [2]]
            @test caps == ones(Int, f_num)
        end
        @testset "with caps" begin
            s_prefs, f_prefs, caps = get_prefs(faculties_restricted, students, faculty_utility, student_utility)

            @test s_prefs == [[], []]
            @test f_prefs == [[], []]
            @test caps == fill(s_num, f_num)
        end
    end
    s_matched = [1, 2]
    s_prefs = [[2, 1], [2, 1]]
    f_matched = [1, 2]
    indptr = [2, 3]
    f_prefs = [[1, 2], [2, 1]]
    @testset "calc_r_faculty" begin
        @test calc_r_faculty(f_matched, indptr, f_prefs) == 1.
        @test calc_r_student(s_matched, s_prefs) = 1.5
    end
end
