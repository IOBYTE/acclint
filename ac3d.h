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

#ifndef _AC3D_H_
#define _AC3D_H_

#define _USE_MATH_DEFINES

#include <array>
#include <set>
#include <map>
#include <vector>
#include <cmath>
#include <regex>
#include <chrono>

class AC3D
{
#define CHECK(func, var, state)                        \
public:                                                \
    void func(bool value) { var = value; }             \
    bool func() const { return var; }                  \
    size_t func##Count() const { return var##_count; } \
private:                                               \
    bool var = state;                                  \
    size_t var##_count = 0;

    // warnings
    CHECK(trailingText, m_trailing_text, true)
    CHECK(blankLine, m_blank_line, false)
    CHECK(duplicateVertices, m_duplicate_vertices, true)
    CHECK(unusedVertex, m_unused_vertex, true)
    CHECK(invalidNormalLength, m_invalid_normal_length, true)
    CHECK(invalidMaterial, m_invalid_material, true)
    CHECK(invalidRefCount, m_invalid_ref_count, true)
    CHECK(extraUVCoordinates, m_extra_uv_coordinates, true)
    CHECK(duplicateMaterials, m_duplicate_materials, true)
    CHECK(unusedMaterial, m_unused_material, true)
    CHECK(missingSurfaces, m_missing_surfaces, true)
    CHECK(duplicateSurfaces, m_duplicate_surfaces, true)
    CHECK(duplicateSurfacesOrder, m_duplicate_surfaces_order, true)
    CHECK(duplicateSurfacesWinding, m_duplicate_surfaces_winding, true)
    CHECK(duplicateSurfaceVertices, m_duplicate_surface_vertices, true)
    CHECK(collinearSurfaceVertices, m_collinear_surface_vertices, true)
    CHECK(multiplePolygonSurface, m_multiple_polygon_surface, true)
    CHECK(surfaceSelfIntersecting, m_surface_self_intersecting, true)
    CHECK(surfaceNotCoplanar, m_surface_not_coplanar, true)
    CHECK(surfaceNotConvex, m_surface_not_convex, true)
    CHECK(surfaceNoTexture, m_surface_no_texture, true)
    CHECK(surfaceStripHole, m_surface_strip_hole, false)
    CHECK(surfaceStripSize, m_surface_strip_size, false)
    CHECK(surfaceStripDegenerate, m_surface_strip_degenerate, false)
    CHECK(surfaceStripDuplicateTriangles, m_surface_strip_duplicate_triangles, false)
    CHECK(surface2SidedOpaque, m_surface_2_sided_opaque, false)
    CHECK(duplicateTriangles, m_duplicate_triangles, false)
    CHECK(floatingPoint, m_floating_point, true)
    CHECK(emptyObject, m_empty_object, true)
    CHECK(extraObject, m_extra_object, true)
    CHECK(missingKids, m_missing_kids, true)
    CHECK(missingTexture, m_missing_texture, true)
    CHECK(duplicateTexture, m_duplicate_texture, true)
    CHECK(ambiguousTexture, m_ambiguous_texture, true)
    CHECK(multipleCrease, m_multiple_crease, true)
    CHECK(multipleFolded, m_multiple_folded, true)
    CHECK(multipleHidden, m_multiple_hidden, true)
    CHECK(multipleLoc, m_multiple_loc, true)
    CHECK(multipleLocked, m_multiple_locked, true)
    CHECK(multipleName, m_multiple_name, true)
    CHECK(multipleRot, m_multiple_rot, true)
    CHECK(multipleSubdiv, m_multiple_subdiv, true)
    CHECK(multipleTexoff, m_multiple_texoff, true)
    CHECK(multipleTexrep, m_multiple_texrep, true)
    CHECK(multipleTexture, m_multiple_texture, true)
    CHECK(differentUV, m_different_uv, true)
    CHECK(groupWithGeometry, m_group_with_geometry, true)
    CHECK(multipleWorld, m_multiple_world, true)
    CHECK(differentSURF, m_different_surf, true)
    CHECK(differentMat, m_different_mat, true)
    CHECK(overlapping2SidedSurface, m_overlapping_2_sided_surface, true)
    CHECK(missingNormal, m_missing_normal, true)
    CHECK(missingUVCoordinates, m_missing_uv_coordinates, true)

    // errors
    CHECK(invalidNormal, m_invalid_normal, true)
    CHECK(invalidVertexIndex, m_invalid_vertex_index, true)
    CHECK(invalidTextureCoordinate, m_invalid_texture_coordinate, true)
    CHECK(invalidMaterialIndex, m_invalid_material_index, true)
    CHECK(invalidSurfaceType, m_invalid_surface_type, true)
    CHECK(invalidToken, m_invalid_token, true)
    CHECK(missingVertex, m_missing_vertex, true)
#undef CHECK

    void showLine(std::istringstream &in) const;
    void showLine(const std::istringstream &in, const std::streampos &pos) const;
    void showLine(std::istream &in, const std::streampos &pos, int offset = 0) const;

public:
    enum class DumpType { group, poly, surf};

    struct RemoveInfo
    {
        RemoveInfo(const std::string &type, const std::string &expression)
        : object_type(type), regular_expression(expression)
        {
        }
        std::string object_type;
        std::regex regular_expression;
    };

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
    void texturePaths(const std::vector<std::string> &paths)
    {
        m_texture_paths = paths;
    }
    size_t getWorldKidCount() const
    {
        return m_objects[0].kids.size();
    }
    size_t getWorldKidCount(size_t kid) const
    {
        if (!m_objects.empty() && m_objects[0].kids.size() > kid)
            return m_objects[0].kids[kid].kids.size();
        return 0;
    }
    void showTimes(bool value)
    {
        m_show_times = value;
    }
    bool showTimes() const
    {
        return m_show_times;
    }
    void threads(unsigned int value)
    {
        m_threads = value;
    }
    unsigned int threads() const
    {
        return m_threads;
    }
    void quite(bool value)
    {
        m_quite = value;
    }
    bool quite() const
    {
        return m_quite;
    }
    void summary(bool value)
    {
        m_summary = value;
    }
    bool summary() const
    {
        return m_summary;
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
    void flatten();
    bool splitPolygons();
    void removeObjects(const RemoveInfo &remove_info);
    void combineTexture();
    void fixOverlapping2SidedSurface();
    void fixSurface2SidedOpaque();
    static std::string getDuration(const std::chrono::time_point<std::chrono::system_clock> &start,
                                   const std::chrono::time_point<std::chrono::system_clock> &end);
    static std::string getTime(const std::chrono::time_point<std::chrono::system_clock> &time);

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
        double cross(const Point2 &other) const
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
        Point3 operator - () const
        {
            return Point3{ -x(), -y(), -z() };
        }
        Point3 &operator += (const Point3 &other)
        {
            x(x() + other.x());
            y(y() + other.y());
            z(z() + other.z());
            return *this;
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
        double angleRadians(const Point3 &other) const
        {
            return acos(dot(other) / (length() * other.length()));
        }

        double angleDegrees(const Point3 &other) const
        {
            return angleRadians(other) * 180.0 / M_PI;
        }
        bool equals(const Point3 &other) const
        {
            static constexpr double  SMALL_NUM = static_cast<double>(std::numeric_limits<double>::epsilon());

            return std::abs(x() - other.x()) < SMALL_NUM &&
                   std::abs(y() - other.y()) < SMALL_NUM &&
                   std::abs(z() - other.z()) < SMALL_NUM;
        }
    };

    class Matrix : public std::array<std::array<double, 4>, 4>
    {
    public:
        Matrix() // identity matrix
        {
            (*this)[0][0] = 1; (*this)[0][1] = 0; (*this)[0][2] = 0; (*this)[0][3] = 0;
            (*this)[1][0] = 0; (*this)[1][1] = 1; (*this)[1][2] = 0; (*this)[1][3] = 0;
            (*this)[2][0] = 0; (*this)[2][1] = 0; (*this)[2][2] = 1; (*this)[2][3] = 0;
            (*this)[3][0] = 0; (*this)[3][1] = 0; (*this)[3][2] = 0; (*this)[3][3] = 1;
        }
        Matrix(double m0,  double m1,  double m2,  double m3,
               double m4,  double m5,  double m6,  double m7,
               double m8,  double m9,  double m10, double m11,
               double m12, double m13, double m14, double m15)
        {
            (*this)[0][0] = m0;  (*this)[0][1] = m1;  (*this)[0][2] = m2;  (*this)[0][3] = m3;
            (*this)[1][0] = m4;  (*this)[1][1] = m5;  (*this)[1][2] = m6;  (*this)[1][3] = m7;
            (*this)[2][0] = m8;  (*this)[2][1] = m9;  (*this)[2][2] = m10; (*this)[2][3] = m11;
            (*this)[3][0] = m12; (*this)[3][1] = m13; (*this)[3][2] = m14; (*this)[3][3] = m15;
        }
        void setLocation(const Point3 &location)
        {
            (*this)[3][0] = location[0];
            (*this)[3][1] = location[1];
            (*this)[3][2] = location[2];
        }

        void setRotation(const std::array<double, 9> &rotation)
        {
            (*this)[0][0] = rotation[0]; (*this)[0][1] = rotation[1]; (*this)[0][2] = rotation[2];
            (*this)[1][0] = rotation[3]; (*this)[1][1] = rotation[4]; (*this)[1][2] = rotation[5];
            (*this)[2][0] = rotation[6]; (*this)[2][1] = rotation[7]; (*this)[2][2] = rotation[8];
        }
        void transformPoint(Point3 &point) const
        {
            Point3 dst;

            double t0 = point[0];
            double t1 = point[1];
            double t2 = point[2];

            dst[0] = t0 * (*this)[0][0] + t1 * (*this)[1][0] + t2 * (*this)[2][0] + (*this)[3][0];
            dst[1] = t0 * (*this)[0][1] + t1 * (*this)[1][1] + t2 * (*this)[2][1] + (*this)[3][1];
            dst[2] = t0 * (*this)[0][2] + t1 * (*this)[1][2] + t2 * (*this)[2][2] + (*this)[3][2];

            point = dst;
        }
        Matrix multiply(const Matrix &matrix)
        {
            Matrix result;

            for (int j = 0; j < 4; j++)
            {
                result[0][j] = matrix[0][0] * (*this)[0][j] +
                               matrix[0][1] * (*this)[1][j] +
                               matrix[0][2] * (*this)[2][j] +
                               matrix[0][3] * (*this)[3][j];

                result[1][j] = matrix[1][0] * (*this)[0][j] +
                               matrix[1][1] * (*this)[1][j] +
                               matrix[1][2] * (*this)[2][j] +
                               matrix[1][3] * (*this)[3][j];

                result[2][j] = matrix[2][0] * (*this)[0][j] +
                               matrix[2][1] * (*this)[1][j] +
                               matrix[2][2] * (*this)[2][j] +
                               matrix[2][3] * (*this)[3][j];

                result[3][j] = matrix[3][0] * (*this)[0][j] +
                               matrix[3][1] * (*this)[1][j] +
                               matrix[3][2] * (*this)[2][j] +
                               matrix[3][3] * (*this)[3][j];
            }

            return result;
        }
        void transformNormal(Point3 &normal) const
        {
            Point3 dst;

            double t0 = normal[0];
            double t1 = normal[1];
            double t2 = normal[2];

            dst[0] = t0 * (*this)[0][0] + t1 * (*this)[1][0] + t2 * (*this)[2][0];
            dst[1] = t0 * (*this)[0][1] + t1 * (*this)[1][1] + t2 * (*this)[2][1];
            dst[2] = t0 * (*this)[0][2] + t1 * (*this)[1][2] + t2 * (*this)[2][2];

            normal = dst;
        }
    };

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
        std::string path;
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

        explicit Mat(size_t index) : LineInfo(), mat(index) { };
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
            if (!vertex.equals(other.vertex))
                return false;

            if (has_normal != other.has_normal)
                return false;

            if (has_normal && !normal.equals(other.normal))
                return false;

            return true;
        }
    };

    enum Difference { None = 0, Order = 1, Winding = 2 };

    struct Surface;
    struct Object;

    struct Triangle
    {
        std::array<Vertex,3> vertices;
        std::array<Ref,3> refs;
        Point3 normal = { 0.0, 0.0, 0.0 };
        bool degenerate = false;

        Triangle(const Vertex& v0, const Vertex& v1, const Vertex& v2, const Ref &r0, const Ref &r1, const Ref &r2)
        {
            vertices[0] = v0;
            vertices[1] = v1;
            vertices[2] = v2;
            refs[0] = r0;
            refs[1] = r1;
            refs[2] = r2;
            degenerate = AC3D::degenerate(v0.vertex, v1.vertex, v2.vertex);

            if (!degenerate)
                normal = AC3D::normalizedNormal(v0.vertex, v1.vertex, v2.vertex);
        }
        bool sameTriangle(const Triangle &triangle, Difference difference) const;
        bool sameTriangle(const Object &object, const Surface &surface, Difference difference) const;
    };

    enum class WindingType { CCW, CW };
    enum class PlaneType { xy, xz, yz };

    struct Plane
    {
        double  distance = 0;
        Point3  normal = { 0.0, 0.0, 0.0 };
        bool valid = false;

        explicit Plane(const std::array<Point3, 3> &points)
        {
            if (!AC3D::degenerate(points))
            {
                normal = (points[1] - points[0]).cross(points[2] - points[0]);
                normal.normalize();
                distance = normal.dot(points[0]);
                valid = true;
            }
        }
        Plane(const Point3 &p0, const Point3 &p1, const Point3 &p2)
        {
            if (!AC3D::degenerate(p0, p1, p2))
            {
                normal = (p1 - p0).cross(p2 - p0);
                normal.normalize();
                distance = normal.dot(p0);
                valid = true;
            }
        }
        Plane(const Point3 &p0, const Point3 &p1, const Point3 &p2, WindingType winding)
        {
            if (!AC3D::degenerate(p0, p1, p2))
            {
                if (winding == WindingType::CCW)
                    normal = (p1 - p0).cross(p2 - p0);
                else
                    normal = (p2 - p0).cross(p1 - p0);

                normal.normalize();
                distance = normal.dot(p0);
                valid = true;
            }
        }
        explicit Plane(const Triangle &triangle)
        {
            if (!triangle.degenerate)
            {
                normal = triangle.normal;
                distance = normal.dot(triangle.vertices[0].vertex);
                valid = true;
            }
        }

        bool isOnPlane(Point3 point) const
        {
            static constexpr double  SMALL_NUM = static_cast<double>(std::numeric_limits<double>::epsilon());

            return std::abs(normal.dot(point) - distance) < SMALL_NUM;
        }

        double distanceToPoint(const Point3 &point) const
        {
            return normal.dot(point) - distance;
        }

        bool isAbovePlane(const Point3 &point) const
        {
            return distanceToPoint(point) >= 0.0;
        }

        bool isBelowPlane(const Point3 &point) const
        {
            return !isAbovePlane(point);
        }

        bool equals(const Plane &other) const
        {
            static constexpr double  SMALL_NUM = static_cast<double>(std::numeric_limits<double>::epsilon());

            return valid && other.valid && std::abs(distance - other.distance) < SMALL_NUM && normal.equals(other.normal);
        }
    };

    struct Mats : public std::vector<Mat>
    {
        bool operator == (const Mats &mats) const
        {
            if (size() != mats.size())
                return false;

            for (size_t i = 0; i < size(); i++)
            {
                if (at(i).mat != mats[i].mat)
                    return false;
            }

            return true;
        }
        bool operator != (const Mats &mats) const
        {
            return !(mats == *this);
        }
    };

    struct Surface : public LineInfo
    {
        unsigned int flags = 0;
        Mats mats;
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
        bool isFlatShaded() const
        {
            return (flags & ShadeMask) == 0;
        }
        bool isSmoothShaded() const
        {
            return (flags & ShadeMask) == Shaded;
        }
        bool isSingleSided() const
        {
            return (flags & SideMask) != DoubleSided;
        }
        void setSingleSided()
        {
            flags = flags & ~DoubleSided;
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
        bool isTriangle() const
        {
            return refs.size() == 3;
        }
        void dump(DumpType dump_type, size_t count, size_t level) const;
    };

    struct Location : public LineInfo
    {
        Point3 location = {0.0, 0.0, 0.0};
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

    struct Shader : public LineInfo
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
        std::vector<Shader> shaders;
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
        Matrix matrix;

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
        bool getVertex(size_t index, Point2 &vertex, PlaneType planeType) const
        {
            if (index >= vertices.size())
                return false;
            switch (planeType)
            {
            case PlaneType::xy:
                vertex.x(vertices[index].vertex.x());
                vertex.y(vertices[index].vertex.y());
                break;
            case PlaneType::xz:
                vertex.x(vertices[index].vertex.x());
                vertex.y(vertices[index].vertex.z());
                break;
            case PlaneType::yz:
                vertex.x(vertices[index].vertex.y());
                vertex.y(vertices[index].vertex.z());
                break;
            }
            return true;
        }
        bool getSurfaceVertex(const Surface &surface,
                              size_t ref,
                              Point2 &vertex,
                              PlaneType planeType) const
        {
            size_t index;
            if (!surface.getIndex(ref, index))
                return false;
            if (!getVertex(index, vertex, planeType))
                return false;
            return true;
        }
        bool sameVertex(size_t index1, size_t index2) const
        {
            if (index1 == index2)
                return true;

            // skip invalid vertex
            if (index1 >= vertices.size() || index2 >= vertices.size())
                return false;

            return vertices[index1].vertex == vertices[index2].vertex;
        }
        size_t getTexturesSize() const
        {
            int actual_textures = static_cast<int>(textures.size());

            if (actual_textures == 0)
                return 0;

            for (int i = actual_textures - 1; i >= 0; i--)
            {
                if (textures[i].name == "empty_texture_no_mapping")
                    actual_textures--;
                else
                    break;
            }
            return actual_textures;
        }
        const std::string &getName() const
        {
            if (!names.empty())
                return names[0].name;

            static const std::string none("");

            return none;
        }
        void setName(const std::string &name)
        {
            names.resize(1);
            names[0].name = quoted_string(name);
        }
        const std::string &getTexture() const
        {
            if (!textures.empty())
                return textures[0].name;

            static const std::string none("");

            return none;
        }

        bool hasTransparentTexture() const;
        bool sameSurface(size_t index1, size_t index2, Difference difference) const;
        void dump(DumpType dump_type, size_t count, size_t level) const;
        void incrementMaterialIndex(size_t num_materials);
        void transform(const Matrix &currentMatrix);
        void removeKids(const RemoveInfo &remove_info);
        bool splitPolygons();
        bool addObject(const Object &object);
        bool sameTextures(const Object &object) const;
    };

    struct NullStream : public std::ostream
    {
    public:
        NullStream() : std::ostream(nullptr) {}
        NullStream(const NullStream &) : std::ostream(nullptr) {}

        template<typename T>
        NullStream &operator<<(T const &) { return *this; }
    };

    NullStream      m_null_stream;

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
    bool            m_quite = false;
    bool            m_summary = false;
    bool            m_show_times = false;
    unsigned int    m_threads = 1;

    Header m_header;
    std::vector<Material> m_materials;
    std::vector<Object> m_objects;
    std::vector<std::string> m_texture_paths;
    bool m_has_world = false;
    std::map<std::string, bool> m_transparent_textures;
    bool m_rename_combine_texture = false;

    struct ConstPoly
    {
        const Object *object;
        Matrix matrix;
    };

    struct Poly
    {
        Object *object;
        Matrix matrix;
    };

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
    std::ostream &warning(size_t line_number = 0); // TODO remove
    std::ostream &warningWithCount(size_t &count, size_t line_number = 0);
    std::ostream &error(size_t line_number = 0);
    std::ostream &errorWithCount(size_t &count, size_t line_number = 0);
    std::ostream &note(size_t line_number = 0);
    void checkTrailing(std::istringstream &iss);
    void checkUnusedMaterial(std::istream &in);
    void checkOverlapping2SidedSurface(std::istream &in);
    void checkOverlapping2SidedSurface(std::istream &in, const ConstPoly &object1, const ConstPoly &object2);
    void checkDuplicateMaterials(std::istream &in);
    void checkUnusedVertex(std::istream &in, const Object &object);
    void checkDuplicateVertices(std::istream &in, const Object &object);
    void checkDuplicateTriangles(std::istream &in, const Object &object);
    void checkMissingSurfaces(std::istream &in, const Object &object);
    void checkDuplicateSurfaces(std::istream &in, const Object &object);
    void checkDuplicateSurfaceVertices(std::istream &in, const Object &object, Surface &surface);
    void checkCollinearSurfaceVertices(std::istream &in, const Object &object, Surface &surface);
    void checkSurfaceCoplanar(std::istream &in, const Object &object, Surface &surface);
    void checkSurfacePolygonType(std::istream &in, const Object &object, Surface &surface);
    void checkSurfaceSelfIntersecting(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceStripHole(std::istream& in, const Object& object, const Surface& surface);
    void checkSurfaceStripSize(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceStripDegenerate(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceStripDuplicateTriangles(std::istream &in, const Object &object, const Surface &surface);
    void checkSurfaceNoTexture(std::istream &in, const Object &object, const Surface &surface);
    void checkSurface2SidedOpaque(std::istream &in, const Object &object, const Surface &surface);
    void checkDifferentSURF(std::istream &in, const Object &object);
    void checkDifferentMat(std::istream& in, const Object& object);
    void checkDifferentUV(std::istream& in, const Object& object);
    void checkGroupWithGeometry(std::istream& in, const Object& object);
    static bool cleanObjects(std::vector<Object> &objects);
    static bool cleanVertices(std::vector<Object> &objects);
    static bool cleanVertices(Object &object);
    static bool cleanSurfaces(std::vector<Object> &objects);
    static bool cleanSurfaces(Object &object);
    static bool cleanMaterials(std::vector<Object> &objects, const std::vector<size_t> &indexes);
    static void convertObjectsToAc(std::vector<Object> &objects);
    static void convertObjectToAc(Object &object);
    static void convertObjectsToAcc(std::vector<Object> &objects);
    static void convertObjectToAcc(Object &object);
    static bool sameMaterial(const Material &material1, const Material &material2);
    static bool sameMaterialParameters(const Material &material1, const Material &material2);
    bool setMaterialUsed(size_t index);
    static bool splitMultipleSURF(std::vector<Object> &kids);
    static bool splitMultipleMat(std::vector<Object> &kids);
    void transform(const Matrix &matrix);
    void combineTexture(const Object &object, std::vector<Object> &objects, std::vector<Object> &transparent_objects);
    static void addConstPoly(std::vector<ConstPoly> &polys, const Object &object, const Matrix &matrix);
    static void addPoly(std::vector<Poly> &polys, Object &object, const Matrix &matrix);
    static void fixOverlapping2SidedSurface(const Poly &object1, const Poly &object2, std::set<Surface *> &surfaces);
    bool hasOpaqueTexture(const Object &object);
    bool hasTransparentTexture(const Object &object);
    void fixSurface2SidedOpaque(Object &object);
    static void getObjects(std::vector<Object *> &polys, Object *object);

    friend std::ostream & operator << (std::ostream &out, const Vertex &v);
    static bool collinear(const Point3 &p1, const Point3 &p2, const Point3 &p3);
    static bool ccw(const AC3D::Point2 &p1, const AC3D::Point2 &p2, const AC3D::Point2 &p3);
    static double closest(const Point3 &p0, const Point3 &p1, const Point3 &p2, const Point3 &p3);
    static Point3 normalizedNormal(const Point3& p0, const Point3& p1, const Point3& p2);
    static Point3 unnormalizedNormal(const Point3 &p0, const Point3 &p1, const Point3 &p2);
    static bool degenerate(const Point3& p0, const Point3& p1, const Point3& p2);
    static bool degenerate(const std::array<Point3, 3> &vertices);
    static bool coplanar(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2);
    static bool trianglesOverlap(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2);
    static size_t getSharedVertexCount(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2);
    static PlaneType getPlaneType(const Point3 &normal);
    static std::array<Point2, 3> convert2D(const std::array<Point3, 3> &vertices, PlaneType planeType);
};

#endif
