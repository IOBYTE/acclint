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

#define _USE_MATH_DEFINES

#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <array>
#include <vector>
#include <cmath>

class AC3D
{
public:
    enum class DumpType { group, poly, surf};

    bool read(const std::string &file);
    bool write(const std::string &file, int version = 0);
    void dump(DumpType dump_type) const;
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
    void notAC3DFile(bool value)
    {
        m_not_ac3d_file = value;
    }
    bool notAC3DFile() const
    {
        return m_not_ac3d_file;
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
    void invalidVertexIndex(bool value)
    {
        m_invalid_vertex_index = value;
    }
    bool invalidVertexIndex() const
    {
        return m_invalid_vertex_index;
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
    void invalidRefCount(bool value)
    {
        m_invalid_ref_count = value;
    }
    bool invalidRefCount() const
    {
        return m_invalid_ref_count;
    }
    void invalidSurfaceType(bool value)
    {
        m_invalid_surface_type = value;
    }
    bool invalidSurfaceType() const
    {
        return m_invalid_surface_type;
    }
    void invalidToken(bool value)
    {
        m_invalid_token = value;
    }
    bool invalidToken() const
    {
        return m_invalid_token;
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
    void collinearSurfaceVertices(bool value)
    {
        m_collinear_surface_vertices = value;
    }
    bool collinearSurfaceVertices() const
    {
        return m_collinear_surface_vertices;
    }
    void multiplePolygonSurface(bool value)
    {
        m_multiple_polygon_surface = value;
    }
    bool multiplePolygonSurface() const
    {
        return m_multiple_polygon_surface;
    }
    void surfaceSelfIntersecting(bool value)
    {
        m_surface_self_intersecting = value;
    }
    bool surfaceSelfIntersecting() const
    {
        return m_surface_self_intersecting;
    }
    void surfaceNotCoplanar(bool value)
    {
        m_surface_not_coplanar = value;
    }
    bool surfaceNotCoplanar() const
    {
        return m_surface_not_coplanar;
    }
    void surfaceNotConvex(bool value)
    {
        m_surface_not_convex = value;
    }
    bool surfaceNotConvex() const
    {
        return m_surface_not_convex;
    }
    void surfaceStripHole(bool value)
    {
        m_surface_strip_hole = value;
    }
    bool surfaceStripHole() const
    {
        return m_surface_strip_hole;
    }
    void surfaceStripSize(bool value)
    {
        m_surface_strip_size = value;
    }
    bool surfaceStripSize() const
    {
        return m_surface_strip_size;
    }
    void surfaceStripDegenerate(bool value)
    {
        m_surface_strip_degenerate = value;
    }
    bool surfaceStripDegenerate() const
    {
        return m_surface_strip_degenerate;
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
    void missingTexture(bool value)
    {
        m_missing_texture = value;
    }
    bool missingTexture() const
    {
        return m_missing_texture;
    }
    void duplicateTexture(bool value)
    {
        m_duplicate_texture = value;
    }
    bool duplicateTexture() const
    {
        return m_duplicate_texture;
    }
    void ambiguousTexture(bool value)
    {
        m_ambiguous_texture = value;
    }
    bool ambiguousTexture() const
    {
        return m_ambiguous_texture;
    }
    void multipleCrease(bool value)
    {
        m_multiple_crease = value;
    }
    bool multipleCrease() const
    {
        return m_multiple_crease;
    }
    void multipleFolded(bool value)
    {
        m_multiple_folded = value;
    }
    bool multipleFolded() const
    {
        return m_multiple_folded;
    }
    void multipleHidden(bool value)
    {
        m_multiple_hidden = value;
    }
    bool multipleHidden() const
    {
        return m_multiple_hidden;
    }
    void multipleLoc(bool value)
    {
        m_multiple_loc = value;
    }
    bool multipleLoc() const
    {
        return m_multiple_loc;
    }
    void multipleLocked(bool value)
    {
        m_multiple_locked = value;
    }
    bool multipleLocked() const
    {
        return m_multiple_locked;
    }
    void multipleName(bool value)
    {
        m_multiple_name = value;
    }
    bool multipleName() const
    {
        return m_multiple_name;
    }
    void multipleRot(bool value)
    {
        m_multiple_rot = value;
    }
    bool multipleRot() const
    {
        return m_multiple_rot;
    }
    void multipleSubdiv(bool value)
    {
        m_multiple_subdiv = value;
    }
    bool multipleSubdiv() const
    {
        return m_multiple_subdiv;
    }
    void multipleTexoff(bool value)
    {
        m_multiple_texoff = value;
    }
    bool multipleTexoff() const
    {
        return m_multiple_texoff;
    }
    void multipleTexrep(bool value)
    {
        m_multiple_texrep= value;
    }
    bool multipleTexrep() const
    {
        return m_multiple_texrep;
    }
    void multipleTexture(bool value)
    {
        m_multiple_texture = value;
    }
    bool multipleTexture() const
    {
        return m_multiple_texture;
    }
    void differentUV(bool value)
    {
        m_different_uv = value;
    }
    bool differentUV() const
    {
        return m_different_uv;
    }
    void groupWithGeometry(bool value)
    {
        m_group_with_geometry = value;
    }
    bool groupWithGeometry() const
    {
        return m_group_with_geometry;
    }
    void multipleWorld(bool value)
    {
        m_multiple_world = value;
    }
    bool multipleWorld() const
    {
        return m_multiple_world;
    }
    void differentSURF(bool value)
    {
        m_different_surf = value;
    }
    bool differentSURF() const
    {
        return m_different_surf;
    }
    void differentMat(bool value)
    {
        m_different_mat = value;
    }
    bool differentMat() const
    {
        return m_different_mat;
    }
    void texturePaths(const std::vector<std::string> &paths)
    {
        m_texture_paths = paths;
    }
    bool clean();
    bool cleanObjects();
    bool cleanVertices();
    bool cleanSurfaces();
    bool cleanMaterials();
    bool fixMultipleWorlds();
    bool splitMultipleSURF();
    bool splitMultipleMat();
    bool merge(const AC3D& ac3d);

    class quoted_string : public std::string
    {
        friend std::ostream & operator << (std::ostream &out, const quoted_string &s);
        friend std::istream & operator >> (std::istream &in, quoted_string &s);
    };

private:
    class Color : public std::array<double,3>
    {
    public:
        bool clip()
        {
            bool clipped = false;

            for (auto &value : *this)
            {
                if (value < 0.0)
                {
                    value = 0.0;
                    clipped = true;
                }
                else if (value > 1.0)
                {
                    value = 1.0;
                    clipped = true;
                }
            }

            return clipped;
        }
    };

    class Point2 : public std::array<double,2>
    {
    public:
        double x() const { return (*this)[0]; }
        double y() const { return (*this)[1]; }
        void x(double value) { (*this)[0] = value; }
        void y(double value) { (*this)[1] = value; }
        Point2 operator - (const Point2 &other) const
        {
            return Point2 { x() - other.x(), y() - other.y() };
        }
        double dot(const Point2 &other) const
        {
            return x() * other.x() + y() * other.y();
        }
        double cross(const Point2 &other)
        {
            return (x() * other.y()) - (y() * other.x());
        }
    };

    class Point3 : public std::array<double,3>
    {
    public:
        double x() const { return (*this)[0]; }
        double y() const { return (*this)[1]; }
        double z() const { return (*this)[2]; }
        void x(double value) { (*this)[0] = value; }
        void y(double value) { (*this)[1] = value; }
        void z(double value) { (*this)[2] = value; }
        Point3 operator + (const Point3 &other) const
        {
            return Point3 { x() + other.x(),
                            y() + other.y(),
                            z() + other.z() };
        }
        Point3 operator - (const Point3 &other) const
        {
            return Point3 { x() - other.x(),
                            y() - other.y(),
                            z() - other.z() };
        }
        Point3 operator * (double value) const
        {
            return Point3 { x() * value, y() * value, z() * value };
        }
        double dot(const Point3 &other) const
        {
            return x() * other.x() + y() * other.y() + z() * other.z();
        }
        Point3 cross(const Point3 &other) const
        {
            return Point3 { y() * other.z() - z() * other.y(),
                            z() * other.x() - x() * other.z(),
                            x() * other.y() - y() * other.x() };
        }
        double length() const
        {
            return std::sqrt(x() * x() + y() * y() + z() * z());
        }
        void normalize()
        {
            const double l = length();
            if (l != 0.0)
            {
                x(x() / l);
                y(y() / l);
                z(z() / l);
            }
        }
    };

    using Matrix = std::array<double,9>;

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
        Color rgb = {0.0, 0.0, 0.0};
        Color amb = {0.0, 0.0, 0.0};
        Color emis = {0.0, 0.0, 0.0};
        Color spec = {0.0, 0.0, 0.0};
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
        Point2 texrep = {0.0, 0.0};
    };

    struct TexOff : public LineInfo
    {
        Point2 texoff = {0.0, 0.0};
    };

    struct SubDiv : public LineInfo
    {
        size_t subdiv = 0;
    };

    struct Ref : public LineInfo
    {
        size_t index = 0;
        std::vector<Point2> coordinates;
        bool duplicate = false;
        bool collinear = false;
    };

    class Refs : public LineInfo, public std::vector<Ref>
    {
    public:
        int declared_size = 0;
    };

    struct Mat : public LineInfo
    {
        size_t mat = 0;

        Mat(size_t number, const std::streampos& pos, size_t index) : LineInfo(number, pos), mat(index) { }
    };

    struct Vertex : public LineInfo
    {
        Point3 vertex = { 0.0, 0.0, 0.0 };
        Point3 normal = { 0.0, 0.0, 0.0 };
        bool has_normal = false;
        bool used = false;

        bool operator == (const Vertex& other) const
        {
            if (vertex != other.vertex)
                return false;

            if (has_normal != other.has_normal)
                return false;

            if (has_normal && normal != other.normal)
                return false;

            return true;
        }
    };

    struct Triangle
    {
        Vertex vertex0;
        Vertex vertex1;
        Vertex vertex2;
        Point3 normal = { 0.0, 0.0, 0.0 };
        bool degenerate = false;

        Triangle(const Vertex& v0, const Vertex& v1, const Vertex& v2) :
            vertex0(v0), vertex1(v1), vertex2(v2)
        {
            degenerate = AC3D::degenerate(v0.vertex, v1.vertex, v2.vertex);

            if (!degenerate)
                normal = AC3D::normal(v0.vertex, v1.vertex, v2.vertex);
        }
    };

    struct Object;

    struct Surface : public LineInfo
    {
        unsigned int flags = 0;
        std::vector<Mat> mats;
        Refs refs;
        bool coplanar = true; // only for Polygon and ClosedLine
        Point3 normal = { 0.0, 0.0, 0.0 }; // only for Polygon
        bool concave = false; // only for Polygon
        std::vector<Triangle> triangleStrip; // only for triangle strips

        enum : unsigned int
        {
            Polygon = 0, ClosedLine = 1, Line = 2, TriangleStrip = 4, Shaded = 0x10, DoubleSided = 0x20,
            TypeMask = 0xf, FaceMask = 0xf0, ShadeMask = 0x10, SideMask = 0x20,
            SingleSidedFlat = 0, SingleSidedSmooth = 0x10, DoubleSidedFlat = 0x20, DoubleSidedSmooth = 0x30
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
        bool isShaded() const
        {
            return (flags & ShadeMask) == Shaded;
        }
        bool isSingleSided() const
        {
            return (flags & SideMask) != DoubleSided;
        }
        bool isDoubleSided() const
        {
            return (flags & SideMask) == DoubleSided;
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
        bool isValidFlags(bool is_ac) const
        {
            if (flags & ~(TypeMask | FaceMask))
                return false;
            if (!(isPolygon() || isClosedLine() || isLine() || (!is_ac && isTriangleStrip())))
                return false;
            if (!(isSingleSidedFlat() || isSingleSidedSmooth() || isDoubleSidedFlat() || isDoubleSidedSmooth()))
                return false;
            return true;
        }
        bool getIndex(size_t ref, size_t &index) const
        {
            if (ref >= refs.size())
                return false;
            index = refs[ref].index;
            return true;
        }
        const std::vector<Triangle> &getTriangleStrip() const
        {
            return triangleStrip;
        }
        void setTriangleStrip(const Object &object);
        void dump(DumpType dump_type, size_t count, size_t level) const;
    };

    struct Location : public LineInfo
    {
        Point3 location = {0.0, 0.0, 0.0};
    };

    struct Rotation : public LineInfo
    {
        Matrix rotation = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
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

    struct Type : public LineInfo
    {
        std::string type;
        int type_offset = 0;
    };

    struct Numvert : public LineInfo
    {
        int number = 0;
        int number_offset = 0;
    };

    struct Numvsurf : public LineInfo
    {
        int number = 0;
        int number_offset = 0;
    };

    struct Object : public LineInfo
    {
        Type type;
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
        Numvert numvert;
        std::vector<Vertex> vertices;
        Numvsurf numsurf;
        std::vector<Surface> surfaces;
        std::vector<Object> kids;

        enum class Plane { xy, xz, yz };

        bool empty() const
        {
            return (type.type == "poly" && vertices.empty() && surfaces.empty() && kids.empty());
        }
        bool getVertex(size_t index, Point3 &vertex) const
        {
            if (index >= vertices.size())
                return false;
            vertex = vertices[index].vertex;
            return true;
        }
        bool getSurfaceVertex(const Surface &surface,
                              size_t ref,
                              Point3 &vertex) const
        {
            size_t index;
            if (!surface.getIndex(ref, index))
                return false;
            if (!getVertex(index, vertex))
                return false;
            return true;
        }
        Plane getPlane(const Point3 &normal) const
        {
            // z largest so use xy plane
            if (std::fabs(normal.x()) < std::fabs(normal.z()) && std::fabs(normal.y()) < std::fabs(normal.z()))
                return Plane::xy;

            // y largest so use xz plane
            if (std::fabs(normal.x()) < std::fabs(normal.y()) && std::fabs(normal.z()) < std::fabs(normal.y()))
                return Plane::xz;

            // use yz plane
            return Plane::yz;
        }
        bool getVertex(size_t index, Point2 &vertex, Plane plane) const
        {
            if (index >= vertices.size())
                return false;
            switch (plane)
            {
            case Plane::xy:
                vertex.x(vertices[index].vertex.x());
                vertex.y(vertices[index].vertex.y());
                break;
            case Plane::xz:
                vertex.x(vertices[index].vertex.x());
                vertex.y(vertices[index].vertex.z());
                break;
            case Plane::yz:
                vertex.x(vertices[index].vertex.y());
                vertex.y(vertices[index].vertex.z());
                break;
            }
            return true;
        }
        bool getSurfaceVertex(const Surface &surface,
                              size_t ref,
                              Point2 &vertex,
                              Plane plane) const
        {
            size_t index;
            if (!surface.getIndex(ref, index))
                return false;
            if (!getVertex(index, vertex, plane))
                return false;
            return true;
        }
        bool sameSurface(size_t index1, size_t index2) const;

        void dump(DumpType dump_type, size_t count, size_t level) const;

        void incrementMaterialIndex(size_t num_materials);
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
    bool            m_not_ac3d_file = true;
    bool            m_trailing_text = true;
    bool            m_blank_line = false;
    bool            m_duplicate_vertices = true;
    bool            m_unused_vertex = true;
    bool            m_invalid_vertex_index = true;
    bool            m_invalid_normal = true;
    bool            m_invalid_material = true;
    bool            m_invalid_material_index = true;
    bool            m_invalid_ref_count = true;
    bool            m_invalid_surface_type = true;
    bool            m_invalid_token = true;
    bool            m_duplicate_materials = true;
    bool            m_unused_material = true;
    bool            m_duplicate_surfaces = true;
    bool            m_duplicate_surface_vertices = true;
    bool            m_collinear_surface_vertices = true;
    bool            m_surface_self_intersecting = true;
    bool            m_surface_not_coplanar = true;
    bool            m_surface_not_convex = true;
    bool            m_surface_strip_hole = true;
    bool            m_surface_strip_size = true;
    bool            m_surface_strip_degenerate = true;
    bool            m_multiple_polygon_surface = true;
    bool            m_floating_point = true;
    bool            m_empty_object = true;
    bool            m_missing_kids = true;
    bool            m_missing_texture = true;
    bool            m_duplicate_texture = true;
    bool            m_ambiguous_texture = true;
    bool            m_multiple_crease = true;
    bool            m_multiple_folded = true;
    bool            m_multiple_hidden = true;
    bool            m_multiple_loc = true;
    bool            m_multiple_locked = true;
    bool            m_multiple_name = true;
    bool            m_multiple_rot = true;
    bool            m_multiple_subdiv = true;
    bool            m_multiple_texoff = true;
    bool            m_multiple_texrep = true;
    bool            m_multiple_texture = true;
    bool            m_different_uv = true;
    bool            m_group_with_geometry = true;
    bool            m_multiple_world = true;
    bool            m_different_surf = true;
    bool            m_different_mat = true;
    bool            m_has_world = false;

    Header m_header;
    std::vector<Material> m_materials;
    std::vector<Object> m_objects;
    std::vector<std::string> m_texture_paths;

    bool readHeader(std::istream &in);
    void writeHeader(std::ostream &out, const Header &header) const;
    bool readTypeAndColor(std::istringstream &in, Color &color, const std::string &expected, const std::string &next);
    bool readColor(std::istringstream &in, Color &color, const std::string &expected, const std::string &next);
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
    void writeVertices(std::ostream &out, const Object &object) const;
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
    void checkCollinearSurfaceVertices(std::istream &in, const Object &object, Surface &surface);
    void checkSurfaceCoplanar(std::istream &in, const Object &object, Surface &surface);
    void checkSurfacePolygonType(std::istream &in, const Object &object, Surface &surface);
    void checkSurfaceSelfIntersecting(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceStripHole(std::istream& in, const Object& object, const Surface& surface);
    void checkSurfaceStripSize(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceStripDegenerate(std::istream &in, const Object &object, const Surface &surface);
    void checkDifferentSURF(std::istream &in, const Object &object);
    void checkDifferentMat(std::istream& in, const Object& object);
    void checkDifferentUV(std::istream& in, const Object& object);
    void checkGroupWithGeometry(std::istream& in, const Object& object);
    bool cleanObjects(std::vector<Object> &objects);
    bool cleanVertices(std::vector<Object> &objects);
    bool cleanVertices(Object &object);
    bool cleanSurfaces(std::vector<Object> &objects);
    bool cleanSurfaces(Object &object);
    bool cleanMaterials(std::vector<Object> &objects, const std::vector<size_t> &indexes);
    void convertObjects(std::vector<Object> &objects);
    void convertObject(Object &object);
    bool sameMaterial(const Material &material1, const Material &material2) const;
    bool sameMaterialParameters(const Material &material1, const Material &material2) const;
    bool setMaterialUsed(size_t index);
    bool splitMultipleSURF(std::vector<Object> &kids);
    bool splitMultipleMat(std::vector<Object> &kids);

    friend std::ostream & operator << (std::ostream &out, const Vertex &v);
    static bool collinear(const Point3 &p1, const Point3 &p2, const Point3 &p3);
    static bool ccw(const AC3D::Point2 &p1, const AC3D::Point2 &p2, const AC3D::Point2 &p3);
    static double closest(const Point3 &p0, const Point3 &p1, const Point3 &p2, const Point3 &p3);
    static Point3 normal(const Point3& p0, const Point3& p1, const Point3& p2);
    static bool degenerate(const Point3& p0, const Point3& p1, const Point3& p2);
};

#endif
