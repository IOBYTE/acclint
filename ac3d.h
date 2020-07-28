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

#ifndef _AC3D_H_
#define _AC3D_H_

#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <array>
#include <vector>

class AC3D
{
public:
    bool read(const std::string &file);
    bool write(const std::string &file);
    size_t warnings() const
    {
        return m_warnings;
    }
    size_t errors() const
    {
        return m_errors;
    }
    void crlf(bool value)
    {
        m_crlf = value;
    }
    bool crlf() const
    {
        return m_crlf;
    }
    void trailingText(bool value)
    {
        m_trailing_text = value;
    }
    bool trailingText() const
    {
        return m_trailing_text;
    }
    void blankLine(bool value)
    {
        m_blank_line = value;
    }
    bool blankLine() const
    {
        return m_blank_line;
    }
    void duplicateVertices(bool value)
    {
        m_duplicate_vertices = value;
    }
    bool duplicateVertices() const
    {
        return m_duplicate_vertices;
    }
    void unusedVertex(bool value)
    {
        m_unused_vertex = value;
    }
    bool unusedVertex() const
    {
        return m_unused_vertex;
    }
    void invalidNormal(bool value)
    {
        m_invalid_normal = value;
    }
    bool invalidNormal() const
    {
        return m_invalid_normal;
    }
    void invalidMaterial(bool value)
    {
        m_invalid_material = value;
    }
    bool invalidMaterial() const
    {
        return m_invalid_material;
    }
    void invalidMaterialIndex(bool value)
    {
        m_invalid_material_index = value;
    }
    bool invalidMaterialIndex() const
    {
        return m_invalid_material_index;
    }
    void duplicateMaterials(bool value)
    {
        m_duplicate_materials = value;
    }
    bool duplicateMaterials() const
    {
        return m_duplicate_materials;
    }
    void unusedMaterial(bool value)
    {
        m_unused_material = value;
    }
    bool unusedMaterial() const
    {
        return m_unused_material;
    }
    void duplicateSurfaces(bool value)
    {
        m_duplicate_surfaces = value;
    }
    bool duplicateSurfaces() const
    {
        return m_duplicate_surfaces;
    }
    void duplicateSurfaceVertices(bool value)
    {
        m_duplicate_surface_vertices = value;
    }
    bool duplicateSurfaceVertices() const
    {
        return m_duplicate_surface_vertices;
    }
    void multiplePolygonSurface(bool value)
    {
        m_multiple_polygon_surface = value;
    }
    bool multiplePolygonSurface() const
    {
        return m_multiple_polygon_surface;
    }
    void floatingPoint(bool value)
    {
        m_floating_point = value;
    }
    bool floatingPoint() const
    {
        return m_floating_point;
    }
    void emptyObject(bool value)
    {
        m_empty_object = value;
    }
    bool emptyObject() const
    {
        return m_empty_object;
    }
    void missingKids(bool value)
    {
        m_missing_kids = value;
    }
    bool missingKids() const
    {
        return m_missing_kids;
    }
    bool clean();
    bool cleanObjects();
    bool cleanVertices();
    bool cleanSurfaces();
    bool cleanMaterials();

    class quoted_string : public std::string
    {
        friend std::ostream & operator << (std::ostream &out, const quoted_string &s);
        friend std::istream & operator >> (std::istream &in, quoted_string &s);
    };

private:
    struct Header
    {
        std::string version = "AC3Db";

        int getVersion() const
        {
            return version[4] == 'b' ? 11 : version[4] == 'c' ? 12 : 11;
        }
    };

    struct LineInfo
    {
        LineInfo() = default;
        LineInfo(size_t number, const std::streampos &pos) : line_number(number), line_pos(pos) { }

        size_t line_number = 0;
        std::streampos line_pos;
    };

    struct Data : public LineInfo
    {
        std::string data;
    };

    struct Material : public LineInfo
    {
        quoted_string name;
        std::array<double,3> rgb = {0.0, 0.0, 0.0};
        std::array<double,3> amb = {0.0, 0.0, 0.0};
        std::array<double,3> emis = {0.0, 0.0, 0.0};
        std::array<double,3> spec = {0.0, 0.0, 0.0};
        double shi = 0.0;
        double trans = 0.0;
        std::vector<Data> data;
        bool version12 = false;
        bool used = false;
    };

    struct Texture : public LineInfo
    {
        quoted_string name;
        std::string type;
    };

    struct TexRep : public LineInfo
    {
        std::array<double,2> texrep = {0.0, 0.0};
    };

    struct TexOff : public LineInfo
    {
        std::array<double,2> texoff = {0.0, 0.0};
    };

    struct SubDiv : public LineInfo
    {
        size_t subdiv = 0;
    };

    struct Ref : public LineInfo
    {
        size_t index = 0;
        std::vector<std::array<double,2>> coordinates;
    };

    struct Surface : public LineInfo
    {
        unsigned int flags;
        std::vector<size_t> mat;
        std::vector<Ref> refs;
        std::vector<size_t> remove;

        enum : unsigned int
        {
            Polygon = 0, ClosedLine = 1, Line = 2, TriangleStrip = 4, TypeMask = 0xf,
            SingleSidedFlat = 0, SingleSidedSmooth = 0x10, DoubleSidedFlat = 0x20, DoubleSidedSmooth = 0x30, FaceMask = 0xf0
        };

        bool isPolygon() const
        {
            return (flags & TypeMask) == Polygon;
        }
        bool isClosedLine() const
        {
            return (flags & TypeMask) == ClosedLine;
        }
        bool isLine() const
        {
            return (flags & TypeMask) == Line;
        }
        bool isTriangleStrip() const
        {
            return (flags & TypeMask) == TriangleStrip;
        }
        bool isSingleSidedFlat() const
        {
            return (flags & FaceMask) == SingleSidedFlat;
        }
        bool isSingleSidedSmooth() const
        {
            return (flags & FaceMask) == SingleSidedSmooth;
        }
        bool isDoubleSidedFlat() const
        {
            return (flags & FaceMask) == DoubleSidedFlat;
        }
        bool isDoubleSidedSmooth() const
        {
            return (flags & FaceMask) == DoubleSidedSmooth;
        }
    };

    struct Vertex : public LineInfo
    {
        std::array<double,3> vertex = {0.0, 0.0, 0.0};
        std::array<double,3> normal = {0.0, 0.0, 0.0};
        bool has_normal = false;
        bool used = false;
    };

    struct Location : public LineInfo
    {
        std::array<double,3> location = {0.0, 0.0, 0.0};
    };

    struct Rotation : public LineInfo
    {
        std::array<double,9> rotation = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    };

    struct Crease : public LineInfo
    {
        double crease = 0.0;
    };

    struct Name : public LineInfo
    {
        quoted_string name;
    };

    struct URL : public LineInfo
    {
        std::string url;
    };

    struct Object
    {
        std::string type;
        std::vector<Name> names;
        std::vector<URL> urls;
        std::vector<Data> data;
        std::vector<TexRep> texreps;
        std::vector<TexOff> texoffs;
        std::vector<SubDiv> subdivs;
        std::vector<Location> locations;
        std::vector<Rotation> rotations;
        std::vector<Crease> creases;
        std::vector<LineInfo> hidden;
        std::vector<LineInfo> locked;
        std::vector<LineInfo> folded;
        std::vector<Texture> textures;
        std::vector<Vertex> vertices;
        LineInfo numsurf;
        int numsurf_number_offset = 0;
        std::vector<Surface> surfaces;
        std::vector<Object> kids;

        bool empty() const
        {
            return (type == "poly" && vertices.empty() && surfaces.empty() && kids.empty());
        }
    };

    std::string     m_file;
    std::string     m_line;
    size_t          m_line_number = 0;
    std::streampos  m_line_pos;
    size_t          m_level = 0;
    size_t          m_errors = 0;
    size_t          m_warnings = 0;
    bool            m_is_utf_8 = false;
    bool            m_is_ac = false;
    bool            m_crlf = false;
    bool            m_trailing_text = true;
    bool            m_blank_line = false;
    bool            m_duplicate_vertices = true;
    bool            m_unused_vertex = true;
    bool            m_invalid_normal = true;
    bool            m_invalid_material = true;
    bool            m_invalid_material_index = true;
    bool            m_duplicate_materials = true;
    bool            m_unused_material = true;
    bool            m_duplicate_surfaces = true;
    bool            m_duplicate_surface_vertices = true;
    bool            m_multiple_polygon_surface = true;
    bool            m_floating_point = true;
    bool            m_empty_object = true;
    bool            m_missing_kids = true;

    Header m_header;
    std::vector<Material> m_materials;
    std::vector<Object> m_objects;

    bool readHeader(std::istream &in);
    void writeHeader(std::ostream &out, const Header &header) const;
    bool readTypeAndColor(std::istringstream &in, std::array<double,3> &color, const std::string &expected, const std::string &next);
    bool readColor(std::istringstream &in, std::array<double,3> &color, const std::string &expected, const std::string &next);
    bool readTypeAndValue(std::istringstream &in, double &value, const std::string &expected, const std::string &next, double min, double max, bool is_float);
    bool readValue(std::istringstream &in, double &value, const std::string &expected, double min, double max, bool is_float);
    bool readData(std::istringstream &iss, std::istream &in, std::string &data);
    void writeData(std::ostream &out, const std::string &data) const;
    bool readMaterial(std::istringstream &in, Material &material);
    bool readMaterial(std::istringstream &first, std::istream &in, Material &material);
    void writeMaterial(std::ostream &out, const Material &material) const;
    bool readSurface(std::istream &in, Surface &surface, Object &object, bool get_line);
    void writeSurface(std::ostream &out, const Surface &surface) const;
    void writeSurfaces(std::ostream &out, const Object &object) const;
    bool readRef(std::istringstream &in, Ref &ref);
    void writeRef(std::ostream &out, const Ref &ref) const;
    bool readObject(std::istringstream &iss, std::istream &in, Object &object);
    void writeObject(std::ostream &out, const Object &object) const;
    bool getLine(std::istream &in);
    bool ungetLine(std::istream &in);
    std::ostream &warning(size_t line_number = 0);
    std::ostream &error(size_t line_number = 0);
    std::ostream &note(size_t line_number = 0);
    void checkTrailing(std::istringstream &iss);
    void checkUnusedMaterial(std::istream &in);
    void checkDuplicateMaterials(std::istream &in);
    void checkUnusedVertex(std::istream &in, const Object &object);
    void checkDuplicateVertices(std::istream &in, const Object &object);
    void checkDuplicateSurfaces(std::istream &in, const Object &object);
    void checkDuplicateSurfaceVertices(std::istream &in, const Object &object, Surface &surface);
    bool cleanObjects(std::vector<Object> &objects);
    bool cleanVertices(std::vector<Object> &objects);
    bool cleanVertices(Object &object);
    bool cleanSurfaces(std::vector<Object> &objects);
    bool cleanSurfaces(Object &object);
    bool cleanMaterials(std::vector<Object> &objects, const std::vector<size_t> &indexes);
    void convertObjects(std::vector<Object> &objects);
    void convertObject(Object &object);
    bool sameVertex(const Vertex &vertex1, const Vertex &vertex2) const;
    bool sameSurface(const Surface &surface1, const Surface &surface2, const Object &object) const;
    bool sameMaterial(const Material &material1, const Material &material2) const;
    bool sameMaterialParameters(const Material &material1, const Material &material2) const;
    bool setMaterialUsed(size_t index);

    friend std::ostream & operator << (std::ostream &out, const Vertex &v);
};

#endif
