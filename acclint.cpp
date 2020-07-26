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
    std::cerr << "Usage: acclint [options] <inputfile> [-o <outputfile>]" << std::endl;
    std::cerr << "Options:" << std::endl;
    std::cerr << "  -Wno-warnings                   Don't show any warnings." << std::endl;
    std::cerr << "  -Wno-trailing-text              Don't show trailing text warnings." << std::endl;
    std::cerr << "  -Wno-blank-line                 Don't show blank line warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-materials        Don't show duplicate materials warnings." << std::endl;
    std::cerr << "  -Wno-unused-material            Don't show unused material warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-vertices         Don't show duplicate vertices warnings." << std::endl;
    std::cerr << "  -Wno-unused-vertex              Don't show unused vertex warnings." << std::endl;
    std::cerr << "  -Wno-invalid-normal             Don't show invalid normal warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surfaces         Don't show duplicate surfaces warnings." << std::endl;
    std::cerr << "  -Wno-duplicate-surface-vertices Don't show duplicate surface vertices warnings." << std::endl;
    std::cerr << "  -Wno-invalid-material           Don't show invaild material warnings." << std::endl;
    std::cerr << "  -Wno-floating-point             Don't show floating point warnings." << std::endl;
    std::cerr << "  -Wno-empty_object               Don't show empty object warnings." << std::endl;
    std::cerr << "  -Wno-missing-kids               Don't show missing kids warnings." << std::endl;
    std::cerr << "  -Wno-errors                     Don't show any errors." << std::endl;
    std::cerr << "  -Wno-invalid-material-index     Don't show invaild material index errors." << std::endl;
    std::cerr << std::endl;
    std::cerr << "By default all warnings and errors are enabled." << std::endl;
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
        exit(EXIT_FAILURE);
    }

    std::string in_file;
    std::string out_file;
    bool trailing_text = true;
    bool blank_line = true;
    bool duplicate_materials = true;
    bool unused_material = true;
    bool duplicate_vertices = true;
    bool unused_vertex = true;
    bool invalid_normal = true;
    bool invalid_material = true;
    bool invalid_material_index = true;
    bool duplicate_surfaces = true;
    bool duplicate_surface_vertices = true;
    bool floating_point = true;
    bool empty_object = true;
    bool missing_kids = true;

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
                exit(EXIT_FAILURE);
            }
        }
        else if (arg == "--version")
        {
            std::cout << "acclint " << acclint_VERSION_MAJOR << "." << acclint_VERSION_MINOR << std::endl;
            exit(EXIT_SUCCESS);
        }
        else if (arg == "--help")
        {
            usage();
            exit(EXIT_SUCCESS);
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
            duplicate_surfaces = false;
            duplicate_surface_vertices = false;
            floating_point = false;
            empty_object = false;
            missing_kids = false;
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
        else if (arg == "-Wno-duplicate-surface-vertices" || arg == "-Wduplicate-surface-vertices")
        {
            duplicate_surface_vertices = arg.compare(2, 3, "no-") != 0;
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
        else if (arg == "-Wno-errors")
        {
            invalid_material_index = false;
        }
        else if (arg == "-Wno-invalid-material-index" || arg == "-Winvalid-material-index")
        {
            invalid_material_index = arg.compare(2, 3, "no-") != 0;
        }
        else if (arg[0] != '-')
        {
            if (in_file.empty())
                in_file = arg;
            else
            {
                std::cerr << "Multiple input files not supported: " << arg << std::endl;
                usage();
                exit(EXIT_FAILURE);
            }
        }
        else
        {
            std::cerr << "Unknown option: " << arg << std::endl;
            usage();
            exit(EXIT_FAILURE);
        }
    }

    AC3D ac3d;

    ac3d.trailingText(trailing_text);
    ac3d.blankLine(blank_line);
    ac3d.duplicateMaterials(duplicate_materials);
    ac3d.unusedMaterial(unused_material);
    ac3d.duplicateVertices(duplicate_vertices);
    ac3d.unusedVertex(unused_vertex);
    ac3d.invalidNormal(invalid_normal);
    ac3d.invalidMaterial(invalid_material);
    ac3d.invalidMaterialIndex(invalid_material_index);
    ac3d.duplicateSurfaces(duplicate_surfaces);
    ac3d.duplicateSurfaceVertices(duplicate_surface_vertices);
    ac3d.floatingPoint(floating_point);
    ac3d.emptyObject(empty_object);
    ac3d.missingKids(missing_kids);

    if (!ac3d.read(in_file))
    {
        std::cerr << ac3d.errors() << " error";
        if (ac3d.errors() > 1)
            std::cerr << "s";
        std::cerr << std::endl;
        exit(EXIT_FAILURE);
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
            exit(EXIT_FAILURE);
        }

        ac3d.clean();

        ac3d.write(out_file);
    }

    return 0;
}

