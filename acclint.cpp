/*
 * acclint - A tool that detects errors in AC3D files.
 * Copyright (C) 2020-2024 Robert Reif
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//---------------------------------------------------------------------------

#ifdef _WIN32
#pragma warning( disable : 4996)
#endif

#include "ac3d.h"
#include "config.h"

#include <iostream>
#include <sstream>
#include <chrono>

namespace {

void usage()
{
    std::cerr << "Usage: acclint [options] [-j <#>] [-T texturepath] <inputfile> [--merge <inputfile>] [-o <outputfile>] [-v <11|12>]" << std::endl;
    std::cerr << "Options:" << std::endl;
    std::cerr << "  -Wno-warnings                          Don't show any warnings." << std::endl;
    std::cerr << "  -Wno-trailing-text                     Don't show trailing text warnings." << std::endl;
    std::cerr << "  -Wno-blank-line                        Don't show blank line warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-materials               Don't show duplicate materials warnings." << std::endl;
    std::cerr << "  -Wno-unused-material                   Don't show unused material warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-vertices                Don't show duplicate vertices warnings." << std::endl;
    std::cerr << "  -Wno-unused-vertex                     Don't show unused vertex warnings." << std::endl;
    std::cerr << "  -Wno-invalid-normal-length             Don't show invalid normal length warnings." << std::endl;
    std::cerr << "  -Wno-missing-normal                    Don't show missing normal warnings." << std::endl;
    std::cerr << "  -Wno-missing-surface                   Don't show missing surface warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces                Don't show duplicate surfaces warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces-order          Don't show duplicate surfaces with different vertex order warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces-winding        Don't show duplicate surfaces with different winding warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surface-vertices        Don't show duplicate surface vertices warnings." << std::endl;
    std::cerr << "  -Wno-collinear-surface-vertices        Don't show collinear surface vertices warnings." << std::endl;
    std::cerr << "  -Wno-surface-self-intersecting         Don't show surface self intersecting warnings." << std::endl;
    std::cerr << "  -Wno-surface-not-coplanar              Don't show surface not coplanar warnings." << std::endl;
    std::cerr << "  -Wno-surface-not-convex                Don't show surface not convex warnings." << std::endl;
    std::cerr << "  -Wno-surface-no-texture                Don't show surface no texture warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-hole                Don't show surface triangle strip with hole warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-size                Don't show surface triangle strip with only 1 triangle warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-duplicate-triangles Don't show surface triangle strip with duplicate triangle warnings." << std::endl;
    std::cerr << "  -Wno-surface-2-sided-opaque            Don't show surface 2 sided opaque warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-triangles               Don't show surface duplicate triangle warnings." << std::endl;
    std::cerr << "  -Wno-multiple-polygon-surface          Don't show multiple polygon surface warnings." << std::endl;
    std::cerr << "  -Wno-missing-texture                   Don't show missing texture warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-texture                 Don't show duplicate texture warnings." << std::endl;
    std::cerr << "  -Wno-ambiguous-texture                 Don't show ambiguous texture warnings." << std::endl;
    std::cerr << "  -Wno-invalid-material                  Don't show invalid material warnings." << std::endl;
    std::cerr << "  -Wno-extra-uv-coordinates              Don't show extra uv coordinates warnings." << std::endl;
    std::cerr << "  -Wno-floating-point                    Don't show floating point warnings." << std::endl;
    std::cerr << "  -Wno-empty-object                      Don't show empty object warnings." << std::endl;
    std::cerr << "  -Wno-extra-object                      Don't show extra object warnings." << std::endl;
    std::cerr << "  -Wno-missing-kids                      Don't show missing kids warnings." << std::endl;
    std::cerr << "  -Wno-multiple-crease                   Don't show multiple crease warnings." << std::endl;
    std::cerr << "  -Wno-multiple-folded                   Don't show multiple folded warnings." << std::endl;
    std::cerr << "  -Wno-multiple-hidden                   Don't show multiple hidden warnings." << std::endl;
    std::cerr << "  -Wno-multiple-loc                      Don't show multiple loc warnings." << std::endl;
    std::cerr << "  -Wno-multiple-locked                   Don't show multiple locked warnings." << std::endl;
    std::cerr << "  -Wno-multiple-name                     Don't show multiple name warnings." << std::endl;
    std::cerr << "  -Wno-multiple-rot                      Don't show multiple rot warnings." << std::endl;
    std::cerr << "  -Wno-multiple-subdiv                   Don't show multiple subdiv warnings." << std::endl;
    std::cerr << "  -Wno-multiple-texoff                   Don't show multiple texoff warnings." << std::endl;
    std::cerr << "  -Wno-multiple-texrep                   Don't show multiple texrep warnings." << std::endl;
    std::cerr << "  -Wno-multiple-texture                  Don't show multiple texture warnings." << std::endl;
    std::cerr << "  -Wno-multiple-world                    Don't show multiple world warnings." << std::endl;
    std::cerr << "  -Wno-different-uv                      Don't show different uv warnings." << std::endl;
    std::cerr << "  -Wno-different-surf                    Don't show different surf warnings." << std::endl;
    std::cerr << "  -Wno-different-mat                     Don't show different mat warnings." << std::endl;
    std::cerr << "  -Wno-group-with-geometry               Don't show group with geometry warnings." << std::endl;
    std::cerr << "  -Wno-overlapping-2-sided-surface       Don't show overlapping 2 sided surface warnings." << std::endl;
    std::cerr << "  -Wno-errors                            Don't show any errors." << std::endl;
    std::cerr << "  -Wno-not-ac3d-file                     Don't show not AC3D file errors." << std::endl;
    std::cerr << "  -Wno-invalid-normal                    Don't show invalid normal errors." << std::endl;
    std::cerr << "  -Wno-invalid-ref-count                 Don't show invalid ref count errors." << std::endl;
    std::cerr << "  -Wno-invalid-material-index            Don't show invalid material index errors." << std::endl;
    std::cerr << "  -Wno-invalid-surface-type              Don't show invalid surface type errors." << std::endl;
    std::cerr << "  -Wno-invalid-surface-count             Don't show invalid surface count errors." << std::endl;
    std::cerr << "  -Wno-invalid-vertex-count              Don't show invalid vertex count errors." << std::endl;
    std::cerr << "  -Wno-invalid-kids-count                Don't show invalid kids count errors." << std::endl;
    std::cerr << "  -Wno-invalid-token                     Don't show invalid token errors." << std::endl;
    std::cerr << "  -Wno-invalid-vertex                    Don't show invalid vertex errors." << std::endl;
    std::cerr << "  -Wno-invalid-vertex-index              Don't show invalid vertex index errors." << std::endl;
    std::cerr << "  -Wno-invalid-texture-coordinate        Don't show invalid texture coordinate errors." << std::endl;
    std::cerr << "  -Wno-missing-uv-coordinates            Don't show missing uv coordinates errors." << std::endl;
    std::cerr << "  -Wno-missing-vertex                    Don't show missing vertex errors." << std::endl;
    std::cerr << "  --dump group|poly|surf                 Dumps the hierarchy of OBJECT and SURF." << std::endl;
    std::cerr << "  -v 11|12                               Output version 11 or 12." << std::endl;
    std::cerr << "  --splitPolygon                         Split polygon surface into seperate triangle surfaces." << std::endl;
    std::cerr << "  --splitSURF                            Split objects with multiple surface types into separate objects." << std::endl;
    std::cerr << "  --splitMat                             Split objects with multiple materials into separate objects." << std::endl;
    std::cerr << "  --flatten                              Flatten objects." << std::endl;
    std::cerr << "  --merge filename                       Merge filename with inputfile." << std::endl;
    std::cerr << "  --removeObjects group|poly|light regex Remove objects that match type and regex." << std::endl;
    std::cerr << "  --combineTexture                       Combine objects by texture." << std::endl;
    std::cerr << "  --fixOverlapping2SidedSurface          Fix overlapping 2 sided surfaces." << std::endl;
    std::cerr << "  --fixSurface2SidedOpaque               Convert opaque 2 sided surfaces to single sided." << std::endl;
    std::cerr << "  --showTimes                            Show execution times of some operations." << std::endl;
    std::cerr << "  --quiet                                Don't show warning messages." << std::endl;
    std::cerr << "  --summary                              Show summary of warnings." << std::endl;

    std::cerr << "  -j #                                   Set number of threads to use." << std::endl;
    std::cerr << "  -l                                     Print the name of the input file." << std::endl;
    std::cerr << std::endl;
    std::cerr << "By default all warnings (except surface-strip-*) and errors are enabled." << std::endl;
    std::cerr << "You can disable specific warnings or errors using the options above." << std::endl;
    std::cerr << "You can also disable all warnings or errors and then reenable specific ones" << std::endl;
    std::cerr << "using the options above but without \"no-\"." << std::endl;
    std::cerr << std::endl;
    std::cerr << "Examples:" << std::endl;
    std::cerr << "  acclint -Wno-trailing-text file.acc             Don't show trailing text warnings." << std::endl;
    std::cerr << "  acclint -Wno-warnings -Wunused-vertex file.acc  Only show unused vertex warnings." << std::endl;
    std::cerr << "  acclint -Wno-warnings -j 8 -T ../../../data/textures original.ac --combineTexture -o new.ac" << std::endl;
}

void showCount(size_t count, const char *text)
{
    if (count > 0)
        std::cout << text << count << std::endl;
}

} // namespace

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        usage();
        return EXIT_FAILURE;
    }

    std::string in_file;
    std::string out_file;

    //warnings
    bool trailing_text = true;
    bool blank_line = true;
    bool duplicate_materials = true;
    bool unused_material = true;
    bool duplicate_vertices = true;
    bool unused_vertex = true;
    bool invalid_vertex = true;
    bool invalid_vertex_index = true;
    bool invalid_texture_coordinate = true;
    bool invalid_normal_length = true;
    bool missing_normal = true;
    bool invalid_material = true;
    bool invalid_material_index = true;
    bool invalid_ref_count = true;
    bool extra_uv_coordinates = true;
    bool missing_uv_coordinates = true;
    bool invalid_surface_type = true;
    bool missing_surfaces = true;
    bool duplicate_surfaces = true;
    bool duplicate_surfaces_order = true;
    bool duplicate_surfaces_winding = true;
    bool duplicate_surface_vertices = true;
    bool collinear_surface_vertices = true;
    bool surface_self_intersecting = true;
    bool surface_not_coplanar = true;
    bool surface_not_convex = true;
    bool surface_no_texture = true;
    bool surface_strip_hole = false;
    bool surface_strip_size = false;
    bool surface_strip_degenerate = false;
    bool surface_strip_duplicate_triangles = true;
    bool surface_2_sided_opaque = false;
    bool fix_surface_2_sided_opaque = false;
    bool duplicate_triangles = true;
    bool multiple_polygon_surface = true;
    bool floating_point = true;
    bool empty_object = true;
    bool extra_object = true;
    bool missing_kids = true;
    bool missing_texture = true;
    bool duplicate_texture = true;
    bool ambiguous_texture = true;
    bool multiple_crease = true;
    bool multiple_folded = true;
    bool multiple_hidden = true;
    bool multiple_locked = true;
    bool multiple_loc = true;
    bool multiple_name = true;
    bool multiple_rot = true;
    bool multiple_subdiv = true;
    bool multiple_texoff = true;
    bool multiple_texrep = true;
    bool multiple_texture = true;
    bool different_uv = true;
    bool group_with_geometry = true;
    bool multiple_world = true;
    bool different_surf = true;
    bool different_mat = true;

    // errors
    bool invalid_normal = true;
    bool invalid_token = true;
    bool missing_vertex = true;
    bool not_ac3d_file = true;
    bool invalid_numsurf = true;
    bool invalid_numvert = true;
    bool invalid_kids_count = true;
    bool more_surf_than_specified = true;

    std::vector<std::string> texture_paths;
    bool dump = false;
    bool splitSURF = false;
    bool splitMat = false;
    bool flatten = false;
    bool splitPolygon = false;
    bool combineTexture = false;
    bool overlapping_2_sided_surface = true;
    bool fix_overlapping_2_sided_surface = false;
    AC3D::DumpType dump_type = AC3D::DumpType::group;
    int version = 0;
    std::vector<std::string> merge_files;
    std::vector<AC3D::RemoveInfo> removes;
    bool show_times = false;
    bool quiet = false;
    bool summary = false;
    unsigned int threads = 1;
    bool listInput = false;

    for (int i = 1; i < argc; ++i)
    {
        std::string arg(argv[i]);
        if (arg == "-o")
        {
            if (i < (argc - 1))
            {
                out_file = argv[i + 1];
                i++;
            }
            else
            {
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "-T")
        {
            if (i < argc - 1)
            {
                texture_paths.emplace_back(argv[i + 1]);
                i++;
            }
            else
            {
                std::cerr << "Missing texture path" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "-j")
        {
            i++;
            if (i == argc)
            {
                std::cerr << "Missing number of threads" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
            arg = argv[i];
            std::istringstream iss(arg);
            iss >> threads;
            if (!iss || threads > 256)
            {
                std::cerr << "Invalid number of threads: " << arg << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "--version")
        {
            std::cout << "acclint " << acclint_VERSION_MAJOR << "." << acclint_VERSION_MINOR << std::endl;
            return EXIT_SUCCESS;
        }
        else if (arg == "--help")
        {
            usage();
            return EXIT_SUCCESS;
        }
        else if (arg == "-Wno-warnings")
        {
            trailing_text = false;
            blank_line = false;
            duplicate_materials = false;
            unused_material = false;
            duplicate_vertices = false;
            unused_vertex = false;
            invalid_material = false;
            invalid_ref_count = false;
            extra_uv_coordinates = false;
            missing_surfaces = false;
            duplicate_surfaces = false;
            duplicate_surfaces_order = false;
            duplicate_surfaces_winding = false;
            duplicate_surface_vertices = false;
            collinear_surface_vertices = false;
            surface_not_coplanar = false;
            surface_self_intersecting = false;
            surface_not_convex = false;
            surface_no_texture = false;
            surface_strip_hole = false;
            surface_strip_size = false;
            surface_strip_degenerate = false;
            surface_strip_duplicate_triangles = false;
            surface_2_sided_opaque = false;
            duplicate_triangles = false;
            multiple_polygon_surface = false;
            floating_point = false;
            empty_object = false;
            extra_object = false;
            missing_kids = false;
            missing_texture = false;
            duplicate_texture = false;
            ambiguous_texture = false;
            multiple_crease = false;
            multiple_folded = false;
            multiple_hidden = false;
            multiple_loc = false;
            multiple_locked = false;
            multiple_name = false;
            multiple_rot = false;
            multiple_subdiv = false;
            multiple_texoff = false;
            multiple_texrep = false;
            multiple_texture = false;
            different_uv = false;
            group_with_geometry = false;
            multiple_world = false;
            different_surf = false;
            different_mat = false;
            overlapping_2_sided_surface = false;
            missing_uv_coordinates = false;
            missing_normal = false;
            invalid_normal_length = false;
        }
        else if (arg == "-Wno-trailing-text" || arg == "-Wtrailing-text")
        {
            trailing_text = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-blank-line" || arg == "-Wblank-line")
        {
            blank_line = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-materials" || arg == "-Wduplicate-materials")
        {
            duplicate_materials = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-unused-material" || arg == "-Wunused-material")
        {
            unused_material = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-vertices" || arg == "-Wduplicate-vertices")
        {
            duplicate_vertices = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-unused-vertex" || arg == "-Wunused-vertex")
        {
            unused_vertex = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-normal-length" || arg == "-Winvalid-normal-length")
        {
            invalid_normal_length = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-normal" || arg == "-Wmissing-normal")
        {
            missing_normal = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-normal" || arg == "-Winvalid-normal")
        {
            invalid_normal = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-material" || arg == "-Winvalid-material")
        {
            invalid_material = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-extra-uv-coordinates" || arg == "-Wextra-uv-coordinates")
        {
            extra_uv_coordinates = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-surfaces" || arg == "-Wmissing-surfaces")
        {
            missing_surfaces = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-surfaces" || arg == "-Wduplicate-surfaces")
        {
            duplicate_surfaces = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-surfaces-order" || arg == "-Wduplicate-surfaces-order")
        {
            duplicate_surfaces_order = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-surfaces-winding" || arg == "-Wduplicate-surfaces-winding")
        {
            duplicate_surfaces_winding = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-surface-vertices" || arg == "-Wduplicate-surface-vertices")
        {
            duplicate_surface_vertices = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-collinear-surface-vertices" || arg == "-Wcollinear-surface-vertices")
        {
            collinear_surface_vertices = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-self-intersecting" || arg == "-Wsurface-self-intersecting")
        {
            surface_self_intersecting = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-not-coplanar" || arg == "-Wsurface-not-coplanar")
        {
            surface_not_coplanar = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-not-convex" || arg == "-Wsurface-not-convex")
        {
            surface_not_convex = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-no-texture" || arg == "-Wsurface-no-texture")
        {
            surface_no_texture = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-strip-hole" || arg == "-Wsurface-strip-hole")
        {
            surface_strip_hole = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-strip-size" || arg == "-Wsurface-strip-size")
        {
            surface_strip_size = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-strip-degenerate" || arg == "-Wsurface-strip-degenerate")
        {
            surface_strip_degenerate = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-strip-duplicate-triangles" || arg == "-Wsurface-strip-duplicate-triangles")
        {
            surface_strip_duplicate_triangles = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-surface-2-sided-opaque" || arg == "-Wsurface-2-sided-opaque")
        {
            surface_2_sided_opaque = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-triangles" || arg == "-Wduplicate-triangles")
        {
            duplicate_triangles = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-polygon-surface" || arg == "-Wmultiple-polygon-surface")
        {
            multiple_polygon_surface = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-floating-point" || arg == "-Wfloating-point")
        {
            floating_point = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-empty-object" || arg == "-Wempty-object")
        {
            empty_object = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-extra-object" || arg == "-Wextra-object")
        {
            extra_object = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-kids" || arg == "-Wmissing-kids")
        {
            missing_kids = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-texture" || arg == "-Wmissing-texture")
        {
            missing_texture = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-duplicate-texture" || arg == "-Wduplicate-texture")
        {
            duplicate_texture = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-ambiguous-texture" || arg == "-Wambiguous-texture")
        {
            ambiguous_texture = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-crease" || arg == "-Wmultiple-crease")
        {
            multiple_crease = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-folded" || arg == "-Wmultiple-folded")
        {
            multiple_folded = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-hidden" || arg == "-Wmultiple-hidden")
        {
            multiple_hidden = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-loc" || arg == "-Wmultiple-loc")
        {
            multiple_loc = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-locked" || arg == "-Wmultiple-locked")
        {
            multiple_locked = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-name" || arg == "-Wmultiple-name")
        {
            multiple_name = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-rot" || arg == "-Wmultiple-rot")
        {
            multiple_rot = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-subdiv" || arg == "-Wmultiple-subdiv")
        {
            multiple_subdiv = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-texoff" || arg == "-Wmultiple-texoff")
        {
            multiple_texoff = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-texrep" || arg == "-Wmultiple-texrep")
        {
            multiple_texrep = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-texture" || arg == "-Wmultiple-texture")
        {
            multiple_texture = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-different-uv" || arg == "-Wdifferent-uv")
        {
            different_uv = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-group-with-geometry" || arg == "-Wgroup-with-geometry")
        {
            group_with_geometry = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-multiple-world" || arg == "-Wmultiple-world")
        {
            multiple_world = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-different-surf" || arg == "-Wdifferent-surf")
        {
            different_surf = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-different-mat" || arg == "-Wdifferent-mat")
        {
            different_mat = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-overlapping-2-sided-surface" || arg == "-Woverlapping-2-sided-surface")
        {
            overlapping_2_sided_surface = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-errors")
        {
            not_ac3d_file = false;
            missing_vertex = false;
            missing_normal = false;
            invalid_normal = false;
            invalid_material_index = false;
            invalid_surface_type = false;
            invalid_token = false;
            invalid_vertex = false;
            invalid_vertex_index = false;
            invalid_texture_coordinate = false;
            invalid_numsurf = false;
            invalid_numvert = false;
            invalid_kids_count = false;
            more_surf_than_specified = false;
        }
        else if (arg == "-Wno-not-ac3d-file" || arg == "-Wnot-ac3d-file")
        {
            not_ac3d_file = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-vertex" || arg == "-Wmissing-vertex")
        {
            missing_vertex = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-missing-uv-coordinates" || arg == "-Wmissing-uv-coordinates")
        {
            missing_uv_coordinates = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-material-index" || arg == "-Winvalid-material-index")
        {
            invalid_material_index = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-ref-count" || arg == "-Winvalid-ref-count")
        {
            invalid_ref_count = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-surface-type" || arg == "-Winvalid-surface-type")
        {
            invalid_surface_type = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-token" || arg == "-Winvalid-token")
        {
            invalid_token = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-vertex-index" || arg == "-Winvalid-vertex-index")
        {
            invalid_vertex_index = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-vertex" || arg == "-Winvalid-vertex")
        {
            invalid_vertex = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-texture-coordinate" || arg == "-Winvalid-texture-coordinate")
        {
            invalid_texture_coordinate = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-vertex-count" || arg == "-Winvalid-vertex-count")
        {
            invalid_numvert = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-surface-count" || arg == "-Winvalid-surface-count")
        {
            invalid_numsurf = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-kids-count" || arg == "-Winvalid-kids-count")
        {
            invalid_kids_count = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-more-surf-than-specified" || arg == "-Wmore-surf-than-specified")
        {
            more_surf_than_specified = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "--splitSURF")
        {
            splitSURF = true;
        }
        else if (arg == "--splitMat")
        {
            splitMat = true;
        }
        else if (arg == "--flatten")
        {
            flatten = true;
        }
        else if (arg == "--splitPolygon")
        {
            splitPolygon = true;
        }
        else if (arg == "--combineTexture")
        {
            combineTexture = true;
        }
        else if (arg == "--fixOverlapping2SidedSurface")
        {
            fix_overlapping_2_sided_surface = true;
        }
        else if (arg == "--fixSurface2SidedOpaque")
        {
            fix_surface_2_sided_opaque = true;
        }
        else if (arg == "--merge")
        {
            if (i < argc - 1)
            {
                merge_files.push_back(argv[i + 1]);
                i++;
            }
            else
            {
                std::cerr << "Missing merge file" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "--removeObjects")
        {
            if ((i + 2) < argc)
            {
                const std::string type = argv[i + 1];
                const std::string expression = argv[i + 2];
                if (type == "group" || type == "poly" || type == "light")
                {
                    try
                    {
                        removes.emplace_back(type, expression);
                        i += 2;
                    }
                    catch (std::regex_error &ex)
                    {
                        std::cerr << "Invalid removeObjects expression:  " << expression << " " << ex.what() << std::endl;
                        usage();
                        return EXIT_FAILURE;
                    }
                }
                else
                {
                    std::cerr << "Invalid removeObjects type: " << type << std::endl;
                    usage();
                    return EXIT_FAILURE;
                }
            }
            else
            {
                std::cerr << "Missing removeObjects parameters" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "--dump")
        {
            i++;
            if (i == argc)
            {
                std::cerr << "Missing dump type" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
            arg = argv[i];
            if (arg == "group")
                dump_type = AC3D::DumpType::group;
            else if (arg == "poly")
                dump_type = AC3D::DumpType::poly;
            else if(arg == "surf")
                dump_type = AC3D::DumpType::surf;
            else
            {
                std::cerr << "Invalid dump type: " << arg << std::endl;
                usage();
                return EXIT_FAILURE;
            }
            dump = true;
        }
        else if (arg == "-v")
        {
            i++;
            if (i == argc)
            {
                std::cerr << "Missing output version" << std::endl;
                usage();
                return EXIT_FAILURE;
            }
            arg = argv[i];
            if (arg == "11")
                version = 11;
            else if (arg == "12")
                version = 12;
            else
            {
                std::cerr << "Invalid output version: " << arg << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else if (arg == "--showTimes")
        {
            show_times = true;
        }
        else if (arg == "--quiet")
        {
            quiet = true;
        }
        else if (arg == "--summary")
        {
            summary = true;
        }
        else if (arg == "-l")
        {
            listInput = true;
        }
        else if (arg[0] != '-')
        {
            if (in_file.empty())
                in_file = arg;
            else
            {
                std::cerr << "Multiple input files not supported: " << arg << std::endl;
                usage();
                return EXIT_FAILURE;
            }
        }
        else
        {
            std::cerr << "Unknown option: " << arg << std::endl;
            usage();
            return EXIT_FAILURE;
        }
    }

    std::chrono::time_point<std::chrono::system_clock> start;

    if (show_times)
    {
        start = std::chrono::system_clock::now();
        std::cout << "acclint started at " << AC3D::getTime(start) << std::endl;
    }

    AC3D ac3d;

    ac3d.notAC3DFile(not_ac3d_file);
    ac3d.trailingText(trailing_text);
    ac3d.blankLine(blank_line);
    ac3d.duplicateMaterials(duplicate_materials);
    ac3d.unusedMaterial(unused_material);
    ac3d.duplicateVertices(duplicate_vertices);
    ac3d.invalidNumvert(invalid_numvert);
    ac3d.invalidKidsCount(invalid_kids_count);
    ac3d.unusedVertex(unused_vertex);
    ac3d.invalidNormalLength(invalid_normal_length);
    ac3d.missingNormal(missing_normal);
    ac3d.invalidNormal(invalid_normal);
    ac3d.invalidMaterial(invalid_material);
    ac3d.invalidMaterialIndex(invalid_material_index);
    ac3d.invalidRefCount(invalid_ref_count);
    ac3d.missingVertex(missing_vertex);
    ac3d.missingUVCoordinates(missing_uv_coordinates);
    ac3d.extraUVCoordinates(extra_uv_coordinates);
    ac3d.invalidNumsurf(invalid_numsurf);
    ac3d.invalidSurfaceType(invalid_surface_type);
    ac3d.invalidVertex(invalid_vertex);
    ac3d.invalidVertexIndex(invalid_vertex_index);
    ac3d.invalidTextureCoordinate(invalid_texture_coordinate);
    ac3d.invalidToken(invalid_token);
    ac3d.missingSurfaces(missing_surfaces);
    ac3d.duplicateSurfaces(duplicate_surfaces);
    ac3d.duplicateSurfacesOrder(duplicate_surfaces_order);
    ac3d.duplicateSurfacesWinding(duplicate_surfaces_winding);
    ac3d.duplicateSurfaceVertices(duplicate_surface_vertices);
    ac3d.collinearSurfaceVertices(collinear_surface_vertices);
    ac3d.surfaceSelfIntersecting(surface_self_intersecting);
    ac3d.surfaceNotCoplanar(surface_not_coplanar);
    ac3d.surfaceNotConvex(surface_not_convex);
    ac3d.surfaceNoTexture(surface_no_texture);
    ac3d.surfaceStripHole(surface_strip_hole);
    ac3d.surfaceStripSize(surface_strip_size);
    ac3d.surfaceStripDegenerate(surface_strip_degenerate);
    ac3d.surfaceStripDuplicateTriangles(surface_strip_duplicate_triangles);
    ac3d.surface2SidedOpaque(surface_2_sided_opaque);
    ac3d.duplicateTriangles(duplicate_triangles);
    ac3d.multiplePolygonSurface(multiple_polygon_surface);
    ac3d.floatingPoint(floating_point);
    ac3d.emptyObject(empty_object);
    ac3d.extraObject(extra_object);
    ac3d.missingKids(missing_kids);
    ac3d.missingTexture(missing_texture);
    ac3d.duplicateTexture(duplicate_texture);
    ac3d.ambiguousTexture(ambiguous_texture);
    ac3d.texturePaths(texture_paths);
    ac3d.multipleCrease(multiple_crease);
    ac3d.multipleFolded(multiple_folded);
    ac3d.multipleHidden(multiple_hidden);
    ac3d.multipleLoc(multiple_loc);
    ac3d.multipleLocked(multiple_locked);
    ac3d.multipleName(multiple_name);
    ac3d.multipleRot(multiple_rot);
    ac3d.multipleSubdiv(multiple_subdiv);
    ac3d.multipleTexoff(multiple_texoff);
    ac3d.multipleTexrep(multiple_texrep);
    ac3d.multipleTexture(multiple_texture);
    ac3d.differentUV(different_uv);
    ac3d.groupWithGeometry(group_with_geometry);
    ac3d.multipleWorld(multiple_world);
    ac3d.differentSURF(different_surf);
    ac3d.differentMat(different_mat);
    ac3d.overlapping2SidedSurface(overlapping_2_sided_surface);
    ac3d.moreSURFThanSpecified(more_surf_than_specified);
    ac3d.showTimes(show_times);
    ac3d.quiet(quiet);
    ac3d.summary(summary);
    ac3d.threads(threads);

    if (listInput)
       std::cerr << in_file << std::endl;

    if (!ac3d.read(in_file))
    {
        if (ac3d.errors() > 0)
        {
            std::cerr << ac3d.errors() << " error";
            if (ac3d.errors() > 1)
                std::cerr << "s";
            std::cerr << std::endl;
        }
        return EXIT_FAILURE;
    }

    if (ac3d.warnings() > 0)
    {
        std::cerr << ac3d.warnings() << " warning";
        if (ac3d.warnings() > 1)
            std::cerr << "s";
        std::cerr << std::endl;

        if (ac3d.summary())
        {
            showCount(ac3d.trailingTextCount(), "trailing text: ");
            showCount(ac3d.blankLineCount(), "blank line: ");
            showCount(ac3d.duplicateVerticesCount(), "duplicate vertices: ");;
            showCount(ac3d.unusedVertexCount(), "unused vertex: ");
            showCount(ac3d.invalidNormalLengthCount(), "invalid normal length: ");
            showCount(ac3d.invalidMaterialCount(), "invalid material: ");
            showCount(ac3d.invalidRefCountCount(), "invalid ref count: ");
            showCount(ac3d.extraUVCoordinatesCount(), "extra uv coordinates: ");
            showCount(ac3d.duplicateMaterialsCount(), "duplicate materials: ");
            showCount(ac3d.unusedMaterialCount(), "unused material: ");
            showCount(ac3d.missingSurfacesCount(), "missing surfaces: ");
            showCount(ac3d.duplicateSurfacesCount(), "duplicate surfaces: ");
            showCount(ac3d.duplicateSurfacesOrderCount(), "duplicate surfaces order: ");
            showCount(ac3d.duplicateSurfacesWindingCount(), "duplicate surfaces winding: ");
            showCount(ac3d.duplicateSurfaceVerticesCount(), "duplicate surface vertices: ");
            showCount(ac3d.collinearSurfaceVerticesCount(), "collinear surface vertices: ");
            showCount(ac3d.multiplePolygonSurfaceCount(), "multiple polygon surface: ");
            showCount(ac3d.surfaceSelfIntersectingCount(), "surface self intersecting: ");
            showCount(ac3d.surfaceNotCoplanarCount(), "surface not coplanar: ");
            showCount(ac3d.surfaceNotConvexCount(), "surface not convex: ");
            showCount(ac3d.surfaceNoTextureCount(), "surface no texture: ");
            showCount(ac3d.surfaceStripHoleCount(), "surface strip hole: ");
            showCount(ac3d.surfaceStripSizeCount(), "surface strip size: ");
            showCount(ac3d.surfaceStripDegenerateCount(), "surface strip degenerate: ");
            showCount(ac3d.surfaceStripDuplicateTrianglesCount(), "surface strip duplicate triangles: ");
            showCount(ac3d.surface2SidedOpaqueCount(), "surface 2 sided opaque: ");
            showCount(ac3d.duplicateTrianglesCount(), "duplicate triangles: ");
            showCount(ac3d.floatingPointCount(), "floating point: ");
            showCount(ac3d.emptyObjectCount(), "empty object: ");
            showCount(ac3d.extraObjectCount(), "extra object: ");
            showCount(ac3d.missingKidsCount(), "missing kids: ");
            showCount(ac3d.missingTextureCount(), "missing texture: ");
            showCount(ac3d.duplicateTextureCount(), "duplicate texture: ");
            showCount(ac3d.ambiguousTextureCount(), "ambiguous texture: ");
            showCount(ac3d.multipleCreaseCount(), "multiple crease: ");
            showCount(ac3d.multipleFoldedCount(), "multiple folded: ");
            showCount(ac3d.multipleHiddenCount(), "multiple hidden: ");
            showCount(ac3d.multipleLocCount(), "multiple loc: ");
            showCount(ac3d.multipleLockedCount(), "multiple locked: ");
            showCount(ac3d.multipleNameCount(), "multiple name: ");
            showCount(ac3d.multipleRotCount(), "multiple rot: ");
            showCount(ac3d.multipleSubdivCount(), "multiple subdiv: ");
            showCount(ac3d.multipleTexoffCount(), "multiple texoff: ");
            showCount(ac3d.multipleTexrepCount(), "multiple texrep: ");
            showCount(ac3d.multipleTextureCount(), "multiple texture: ");
            showCount(ac3d.differentUVCount(), "different uv: ");
            showCount(ac3d.groupWithGeometryCount(), "group with geometry: ");
            showCount(ac3d.multipleWorldCount(), "multiple world: ");
            showCount(ac3d.differentSURFCount(), "different surf: ");
            showCount(ac3d.differentMatCount(), "different mat: ");
            showCount(ac3d.overlapping2SidedSurfaceCount(), "overlapping 2 sided surface: ");

            // errors
            showCount(ac3d.missingNormalCount(), "missing normal: ");
            showCount(ac3d.missingUVCoordinatesCount(), "missing uv coordinates: ");
            showCount(ac3d.invalidMaterialIndexCount(), "invalid material index: ");
            showCount(ac3d.invalidSurfaceTypeCount(), "invalid surface type: ");
        }
    }

    if (ac3d.errors() > 0)
    {
        std::cerr << ac3d.errors() << " error";
        if (ac3d.errors() > 1)
            std::cerr << "s";
        std::cerr << std::endl;

        if (ac3d.summary())
        {
            showCount(ac3d.invalidVertexCount(), "invalid vertex: ");
            showCount(ac3d.invalidVertexIndexCount(), "invalid vertex index: ");
            showCount(ac3d.invalidNormalCount(), "invalid normal: ");
            showCount(ac3d.invalidTextureCoordinateCount(), "invalid texture coordinate: ");
            showCount(ac3d.invalidTokenCount(), "invalid token: ");
            showCount(ac3d.invalidNumsurfCount(), "invalid surface count: ");
            showCount(ac3d.invalidNumvertCount(), "invalid vertex count: ");
            showCount(ac3d.invalidKidsCountCount(), "invalid kids count: ");
            showCount(ac3d.missingVertexCount(), "missing vertex: ");
            showCount(ac3d.moreSURFThanSpecifiedCount(), "more SURF than specified");
        }
    }

    if (!out_file.empty())
    {
        if (ac3d.errors() > 0)
        {
            std::cerr << "Can't write output file because input file has fatal errors" << std::endl;
            return EXIT_FAILURE;
        }

        for (const auto &filename : merge_files)
        {
            std::cout << "Reading: " << filename << std::endl;

            AC3D to_merge;

            if (!to_merge.read(filename))
            {
                if (to_merge.errors() > 0)
                {
                    std::cerr << to_merge.errors() << " error";
                    if (to_merge.errors() > 1)
                        std::cerr << "s";
                    std::cerr << std::endl;
                }

                return EXIT_FAILURE;
            }

            if (to_merge.warnings() > 0)
            {
                std::cerr << to_merge.warnings() << " warning";
                if (to_merge.warnings() > 1)
                    std::cerr << "s";
                std::cerr << std::endl;
            }

            if (to_merge.errors() > 0)
            {
                std::cerr << to_merge.errors() << " error";
                if (to_merge.errors() > 1)
                    std::cerr << "s";
                std::cerr << std::endl;
            }

            std::cout << "Merging: " << filename << std::endl;

            if (!ac3d.merge(to_merge))
            {
                std::cerr << "Couldn't merge " << filename << std::endl;
                return EXIT_FAILURE;
            }
        }

        for (const auto &remove : removes)
            ac3d.removeObjects(remove);

        if (flatten)
            ac3d.flatten();

        if (splitPolygon)
            ac3d.splitPolygons();

        if (splitSURF)
            ac3d.splitMultipleSURF();

        if (splitMat)
            ac3d.splitMultipleMat();

        ac3d.fixMultipleWorlds();

        ac3d.clean();

        if (fix_surface_2_sided_opaque)
            ac3d.fixSurface2SidedOpaque();

        if (fix_overlapping_2_sided_surface)
        {
            ac3d.flatten();
            ac3d.clean();

            ac3d.fixOverlapping2SidedSurface();
        }

        if (combineTexture)
        {
            ac3d.combineTexture();
            ac3d.clean();

            std::cout << "combineTexture: " << ac3d.getWorldKidCount(0)
                      << " opaque textures "  << ac3d.getWorldKidCount(1)
                      << " transparent textures" << std::endl;
        }

        ac3d.write(out_file, version);
    }

    if (dump)
        ac3d.dump(dump_type);

    if (show_times)
    {
        const std::chrono::time_point<std::chrono::system_clock> end = std::chrono::system_clock::now();
        std::cout << "acclint finished at " << AC3D::getTime(end) << " duration: " << AC3D::getDuration(start, end) << std::endl;
    }

    return EXIT_SUCCESS;
}
