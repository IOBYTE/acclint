/*
 * acclint - A tool that detects errors in AC3D files.
 * Copyright (C) 2020 Robert Reif
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

#include "ac3d.h"
#include "config.h"

void usage()
{
    std::cerr << "Usage: acclint [options] [-T texturepath] <inputfile> [--merge <inputfile>] [-o <outputfile>] [-v <11|12>]" << std::endl;
    std::cerr << "Options:" << std::endl;
    std::cerr << "  -Wno-warnings                          Don't show any warnings." << std::endl;
    std::cerr << "  -Wno-trailing-text                     Don't show trailing text warnings." << std::endl;
    std::cerr << "  -Wno-blank-line                        Don't show blank line warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-materials               Don't show duplicate materials warnings." << std::endl;
    std::cerr << "  -Wno-unused-material                   Don't show unused material warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-vertices                Don't show duplicate vertices warnings." << std::endl;
    std::cerr << "  -Wno-unused-vertex                     Don't show unused vertex warnings." << std::endl;
    std::cerr << "  -Wno-invalid-normal                    Don't show invalid normal warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces                Don't show duplicate surfaces warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces-order          Don't show duplicate surfaces with different vertex order warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces-winding        Don't show duplicate surfaces with different winding warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surface-vertices        Don't show duplicate surface vertices warnings." << std::endl;
    std::cerr << "  -Wno-collinear-surface-vertices        Don't show collinear surface vertices warnings." << std::endl;
    std::cerr << "  -Wno-surface-self-intersecting         Don't show surface self intersecting warnings." << std::endl;
    std::cerr << "  -Wno-surface-not-coplanar              Don't show surface not coplanar warnings." << std::endl;
    std::cerr << "  -Wno-surface-not-convex                Don't show surface not convex warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-hole                Don't show surface triangle strip with hole warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-size                Don't show surface triangle strip with only 1 triangle warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-size                Don't show surface triangle strip with only 1 triangle warnings." << std::endl;
    std::cerr << "  -Wno-surface-strip-duplicate-triangles Don't show surface triangle strip with duplicate triangle warnings." << std::endl;
    std::cerr << "  -Wno-multiple-polygon-surface          Don't show multiple polygon surface warnings." << std::endl;
    std::cerr << "  -Wno-missing-texture                   Don't show missing texture warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-texture                 Don't show duplicate texture warnings." << std::endl;
    std::cerr << "  -Wno-ambiguous-texture                 Don't show ambiguous texture warnings." << std::endl;
    std::cerr << "  -Wno-invalid-material                  Don't show invalid material warnings." << std::endl;
    std::cerr << "  -Wno-invalid-ref-count                 Don't show invalid ref count errors." << std::endl;
    std::cerr << "  -Wno-floating-point                    Don't show floating point warnings." << std::endl;
    std::cerr << "  -Wno-empty_object                      Don't show empty object warnings." << std::endl;
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
    std::cerr << "  -Wno-errors                            Don't show any errors." << std::endl;
    std::cerr << "  -Wno-not-ac3d-file                     Don't show not AC3D file errors." << std::endl;
    std::cerr << "  -Wno-invalid-material-index            Don't show invalid material index errors." << std::endl;
    std::cerr << "  -Wno-invalid-surface-type              Don't show invalid surface type errors." << std::endl;
    std::cerr << "  -Wno-invalid-token                     Don't show invalid token errors." << std::endl;
    std::cerr << "  -Wno-invalid-vertex-index              Don't show invalid vertex index errors." << std::endl;
    std::cerr << "  --dump group|poly|surf                 Dumps the hierarchy of OBJECT and SURF." << std::endl;
    std::cerr << "  -v 11|12                               Output version 11 or 12." << std::endl;
    std::cerr << "  --splitSURF                            Split objects with multiple surface types into seperate objects." << std::endl;
    std::cerr << "  --splitMat                             Split objects with multiple materials into seperate objects." << std::endl;
    std::cerr << "  --merge filename                       Merge filename with inputfile." << std::endl;
    std::cerr << std::endl;
    std::cerr << "By default all warnings (except surface-strip-*) and errors are enabled." << std::endl;
    std::cerr << "You can disable specific warnings or errors using the options above." << std::endl;
    std::cerr << "You can also disable all warnings or errors and then reenable specific ones" << std::endl;
    std::cerr << "using the options above but without \"no-\"." << std::endl;
    std::cerr << std::endl;
    std::cerr << "Examples:" << std::endl;
    std::cerr << "  acclint -Wno-trailing-text file.acc             Don't show trailing text warnings." << std::endl;
    std::cerr << "  acclint -Wno-warnings -Wunused-vertex file.acc  Only show unused vertex warnings." << std::endl;
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        usage();
        return EXIT_FAILURE;
    }

    std::string in_file;
    std::string out_file;
    bool not_ac3d_file = true;
    bool trailing_text = true;
    bool blank_line = true;
    bool duplicate_materials = true;
    bool unused_material = true;
    bool duplicate_vertices = true;
    bool unused_vertex = true;
    bool invalid_vertex_index = true;
    bool invalid_normal = true;
    bool invalid_material = true;
    bool invalid_material_index = true;
    bool invalid_ref_count = true;
    bool invalid_surface_type = true;
    bool invalid_token = true;
    bool duplicate_surfaces = true;
    bool duplicate_surfaces_order = true;
    bool duplicate_surfaces_winding = true;
    bool duplicate_surface_vertices = true;
    bool collinear_surface_vertices = true;
    bool surface_self_intersecting = true;
    bool surface_not_coplanar = true;
    bool surface_not_convex = true;
    bool surface_strip_hole = false;
    bool surface_strip_size = false;
    bool surface_strip_degenerate = false;
    bool surface_strip_duplicate_triangles = true;
    bool multiple_polygon_surface = true;
    bool floating_point = true;
    bool empty_object = true;
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
    std::vector<std::string> texture_paths;
    bool dump = false;
    bool splitSURF = false;
    bool splitMat = false;
    AC3D::DumpType dump_type = AC3D::DumpType::group;
    int version = 0;
    std::vector<std::string> merge_files;

    for (int i = 1; i < argc; ++i)
    {
        std::string arg(argv[i]);
        if (arg == "-o")
        {
            if (i < argc)
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
            if (i < argc)
            {
                texture_paths.emplace_back(argv[i + 1]);
                i++;
            }
            else
            {
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
            duplicate_surfaces = false;
            duplicate_surfaces_order = false;
            duplicate_surfaces_winding = false;
            duplicate_surface_vertices = false;
            collinear_surface_vertices = false;
            surface_not_coplanar = false;
            surface_self_intersecting = false;
            surface_not_convex = false;
            surface_strip_hole = false;
            surface_strip_size = false;
            surface_strip_degenerate = false;
            surface_strip_duplicate_triangles = false;
            multiple_polygon_surface = false;
            floating_point = false;
            empty_object = false;
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
        else if (arg == "-Wno-invalid-normal" || arg == "-Winvalid-normal")
        {
            invalid_normal = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg == "-Wno-invalid-material" || arg == "-Winvalid-material")
        {
            invalid_material = arg.compare(2, 3, "no-") != 0;
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
        else if (arg == "-Wno-errors")
        {
            not_ac3d_file = false;
            invalid_material_index = false;
            invalid_surface_type = false;
            invalid_token = false;
            invalid_vertex_index = false;
        }
        else if (arg == "-Wno-not-ac3d-file" || arg == "-Wnot-ac3d-file")
        {
            not_ac3d_file = arg.compare(2, 3, "no-") != 0;
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
        else if (arg == "--splitSURF")
        {
            splitSURF = true;
        }
        else if (arg == "--splitMat")
        {
            splitMat = true;
        }
        else if (arg == "--merge")
        {
            if (i < argc)
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

    AC3D ac3d;

    ac3d.notAC3DFile(not_ac3d_file);
    ac3d.trailingText(trailing_text);
    ac3d.blankLine(blank_line);
    ac3d.duplicateMaterials(duplicate_materials);
    ac3d.unusedMaterial(unused_material);
    ac3d.duplicateVertices(duplicate_vertices);
    ac3d.unusedVertex(unused_vertex);
    ac3d.invalidNormal(invalid_normal);
    ac3d.invalidMaterial(invalid_material);
    ac3d.invalidMaterialIndex(invalid_material_index);
    ac3d.invalidRefCount(invalid_ref_count);
    ac3d.invalidSurfaceType(invalid_surface_type);
    ac3d.invalidVertexIndex(invalid_vertex_index);
    ac3d.invalidToken(invalid_token);
    ac3d.duplicateSurfaces(duplicate_surfaces);
    ac3d.duplicateSurfacesOrder(duplicate_surfaces_order);
    ac3d.duplicateSurfacesWinding(duplicate_surfaces_winding);
    ac3d.duplicateSurfaceVertices(duplicate_surface_vertices);
    ac3d.collinearSurfaceVertices(collinear_surface_vertices);
    ac3d.surfaceSelfIntersecting(surface_self_intersecting);
    ac3d.surfaceNotCoplanar(surface_not_coplanar);
    ac3d.surfaceNotConvex(surface_not_convex);
    ac3d.surfaceStripHole(surface_strip_hole);
    ac3d.surfaceStripSize(surface_strip_size);
    ac3d.surfaceStripDegenerate(surface_strip_degenerate);
    ac3d.surfaceStripDuplicateTriangles(surface_strip_duplicate_triangles);
    ac3d.multiplePolygonSurface(multiple_polygon_surface);
    ac3d.floatingPoint(floating_point);
    ac3d.emptyObject(empty_object);
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
    }

    if (ac3d.errors() > 0)
    {
        std::cerr << ac3d.errors() << " error";
        if (ac3d.errors() > 1)
            std::cerr << "s";
        std::cerr << std::endl;
    }

    if (!out_file.empty())
    {
        if (ac3d.errors() > 0)
        {
            std::cerr << "Can't write output file because input file has fatal errors" << std::endl;
            return EXIT_FAILURE;
        }

        for (const auto& filename : merge_files)
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

        if (ac3d.fixMultipleWorlds())
        {
            if (splitSURF)
                ac3d.splitMultipleSURF();

            if (splitMat)
                ac3d.splitMultipleMat();

            ac3d.clean();

            ac3d.write(out_file, version);
        }
    }

    if (dump)
        ac3d.dump(dump_type);

    return EXIT_SUCCESS;
}

