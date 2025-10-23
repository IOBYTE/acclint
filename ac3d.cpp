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

#if defined(_WIN32)
#pragma warning( disable : 4996)
#endif

#include "ac3d.h"
#include <limits>
#include <filesystem>
#include <map>
#include <set>
#include <string>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <cstdio>
#include <cmath>
#include <chrono>
#include <omp.h>

#include <png.h>

#include "triangleintersects.hpp"

const std::string MATERIAL_token("MATERIAL");
const std::string rgb_token("rgb");
const std::string amb_token("amb");
const std::string emis_token("emis");
const std::string spec_token("spec");
const std::string shi_token("shi");
const std::string trans_token("trans");
const std::string data_token("data");
const std::string MAT_token("MAT");
const std::string ENDMAT_token("ENDMAT");
const std::string OBJECT_token("OBJECT");
const std::string name_token("name");
const std::string texture_token("texture");
const std::string shader_token("shader");
const std::string texrep_token("texrep");
const std::string texoff_token("texoff");
const std::string subdiv_token("subdiv");
const std::string crease_token("crease");
const std::string rot_token("rot");
const std::string loc_token("loc");
const std::string url_token("url");
const std::string hidden_token("hidden");
const std::string locked_token("locked");
const std::string folded_token("folded");
const std::string numvert_token("numvert");
const std::string numsurf_token("numsurf");
const std::string SURF_token("SURF");
const std::string mat_token("mat");
const std::string refs_token("refs");
const std::string kids_token("kids");
const std::string empty_token;
const std::string world_token("world");
const std::string poly_token("poly");
const std::string group_token("group");
const std::string light_token("light");

std::ostream & operator << (std::ostream &out, const AC3D::quoted_string &s)
{
    if (s == "empty_texture_no_mapping")
        out << reinterpret_cast<const std::string &>(s);
    else
        out << '\"' << reinterpret_cast<const std::string &>(s) << '\"';
    return out;
}

std::istream & operator >> (std::istream &in, AC3D::quoted_string &s)
{
    in >> std::ws;

    if (in.peek() != '\"')
        in >> reinterpret_cast<std::string &>(s);
    else
    {
        in.get(); // skip quote

        while (in.good())
        {
            std::istream::char_type c;
            in.get(c);
            if (c == '\"' && (s.empty() || s.back() != '\\'))
                break;
            s += c;
        }
    }

    return in;
}

template <size_t s>
std::ostream & operator << (std::ostream &out, const std::array<double,s> &a)
{
    for (size_t i = 0; i < s; ++i)
    {
        if (i != 0)
            out << ' ';
        out << std::setprecision(12) << a[i];
    }
    return out;
}

template <size_t s>
std::istream & operator >> (std::istream &in, std::array<double,s> &a)
{
    for (size_t i = 0; i < s; ++i)
        in >> std::setprecision(12) >> a[i];

    return in;
}

std::ostream & operator << (std::ostream &out, const AC3D::Vertex &v)
{
    out << v.vertex;
    if (v.has_normal)
        out << " " << v.normal;
    return out;
}

bool isWhitespace(const std::string &s)
{
    return (s.find_first_not_of(" \n\r\t") == std::string::npos);
}

bool hasTrailing(const std::istringstream &s)
{
    std::streambuf *buf = s.rdbuf();
    const std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
    const std::streampos end = buf->pubseekoff(0, std::ios_base::end, std::ios_base::in);
    buf->pubseekpos(pos, std::ios_base::in);
    return end != pos;
}

std::string getTrailing(const std::istringstream &s)
{
    std::streambuf *buf = s.rdbuf();
    const std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
    buf->pubseekpos(pos, std::ios_base::in);
    return s.str().substr(pos);
}

size_t offsetOfToken(const std::istringstream &in, size_t index)
{
    const std::string text = in.str();
    size_t token_count = 0;
    size_t current_offset = 0;
    bool in_token = false;

    for (auto c : text)
    {
        if (!in_token && c != ' ')
        {
            in_token = true;

            if (token_count == index)
                return current_offset;

            token_count++;
        }
        else if (in_token && c == ' ')
        {
            in_token = false;
        }
        current_offset++;
    }

    return current_offset;
}

void AC3D::showLine(std::istringstream &in) const
{
    if (!m_quite)
    {
        std::cerr << in.str() << std::endl;

        std::streambuf *buf = in.rdbuf();
        const std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
        buf->pubseekpos(pos, std::ios_base::in);

        for (int i = 0; i < pos; ++i)
            std::cerr << ' ';
        std::cerr << '^' << std::endl;
    }
}

void AC3D::showLine(const std::istringstream &in, const std::streampos &pos) const
{
    if (!m_quite)
    {
        std::cerr << in.str() << std::endl;

        for (int i = 0; i < pos; ++i)
            std::cerr << ' ';
        std::cerr << '^' << std::endl;
    }
}

void AC3D::showLine(std::istream &in, const std::streampos &pos, int offset) const
{
    if (!m_quite)
    {
        const std::streampos current = in.tellg();
        std::string line;

        in.seekg(pos);
        std::getline(in, line);

        // remove CR
        if (line.back() == '\r')
            line.pop_back();
        std::cerr << line << std::endl;
        if (offset < 0)
            offset = static_cast<int>(line.size());
        for (int i = 0; i < offset; ++i)
            std::cerr << ' ';
        std::cerr << '^' << std::endl;

        in.seekg(current);
    }
}

class newline
{
    bool m_crlf;
public:
    explicit newline(bool crlf) : m_crlf(crlf) {}

    friend std::ostream &operator << (std::ostream &os, const newline &nl)
    {
        if (nl.m_crlf)
            os << '\r';
        os << '\n';
        return os;
    }
};

bool AC3D::getLine(std::istream &in)
{
    m_line_pos = in.tellg();

    bool empty = false;

    do
    {
        empty = false;

        std::getline(in, m_line);

        if (!in)
            return false;

        m_line_number++;

        if (!m_line.empty() && m_line.back() == '\r')
        {
            m_line.pop_back();
            m_crlf = true;
        }

        if (m_line.empty() || isWhitespace(m_line))
        {
            if (m_blank_line)
                warningWithCount(m_blank_line_count) << "blank line" << std::endl;
            empty = true;
        }
    } while (empty);

    return true;
}

bool AC3D::ungetLine(std::istream &in)
{
    in.seekg(m_line_pos);
    m_line_number--;
    return true;
}

std::ostream &AC3D::warning(size_t line_number)
{
    m_warnings++;
    if (!m_quite)
    {
        if (line_number > 0)
            std::cerr << m_file << ":" << line_number << " warning: ";
        else
            std::cerr << m_file << ":" << m_line_number << " warning: ";
    }
    return std::cerr;
}

std::ostream &AC3D::warningWithCount(size_t &count, size_t line_number)
{
    count++;
    m_warnings++;
    if (!m_quite)
    {
        if (line_number > 0)
            std::cerr << m_file << ":" << line_number << " warning: ";
        else
            std::cerr << m_file << ":" << m_line_number << " warning: ";
        return std::cerr;
    }
    return m_null_stream;
}

std::ostream &AC3D::error(size_t line_number)
{
    m_errors++;
    if (line_number > 0)
        std::cerr << m_file << ":" << line_number << " error: ";
    else
        std::cerr << m_file << ":" << m_line_number << " error: ";
    return std::cerr;
}

std::ostream &AC3D::errorWithCount(size_t &count, size_t line_number)
{
    count++;
    m_errors++;
    if (!m_quite)
    {
        if (line_number > 0)
            std::cerr << m_file << ":" << line_number << " error: ";
        else
            std::cerr << m_file << ":" << m_line_number << " error: ";
        return std::cerr;
    }
    return m_null_stream;
}

std::ostream &AC3D::note(size_t line_number)
{
    if (!m_quite)
    {
        std::cerr << m_file << ":" << line_number << " note: ";
        return std::cerr;
    }
    return m_null_stream;
}

void AC3D::checkTrailing(std::istringstream &iss)
{
    if (!m_trailing_text)
        return;

    const std::streampos pos = iss.tellg();
    if (hasTrailing(iss))
    {
        warningWithCount(m_trailing_text_count) << "trailing text: \"" << getTrailing(iss) << "\"" << std::endl;
        showLine(iss, pos);
    }
}

bool AC3D::readRef(std::istringstream &in, AC3D::Ref &ref)
{
    ref.line_number = m_line_number;
    ref.line_pos = m_line_pos;

    in >> ref.index;

    if (!in)
    {
        error() << "reading index" << std::endl;
        showLine(in);
        return false;
    }

    Point2 uv{ 0.0, 0.0 };

    in >> uv;

    if (in)
    {
        ref.coordinates.push_back(uv);
        if (hasTrailing(in))
        {
            std::streampos pos = in.tellg();
            std::string trailing = getTrailing(in);
            if (m_is_ac)
            {
                if (m_trailing_text)
                {
                    warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                    showLine(in, pos);
                }
            }
            else
            {
                in >> uv;
                if (in)
                {
                    ref.coordinates.push_back(uv);
                    if (hasTrailing(in))
                    {
                        pos = in.tellg();
                        trailing = getTrailing(in);
                        in >> uv;
                        if (in)
                        {
                            ref.coordinates.push_back(uv);
                            if (hasTrailing(in))
                            {
                                pos = in.tellg();
                                trailing = getTrailing(in);
                                in >> uv;
                                if (in)
                                {
                                    ref.coordinates.push_back(uv);
                                    if (hasTrailing(in))
                                    {
                                        if (m_trailing_text)
                                        {
                                            pos = in.tellg();
                                            trailing = getTrailing(in);
                                            warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                                            showLine(in, pos);
                                        }
                                    }
                                }
                                else
                                {
                                    if (isWhitespace(trailing))
                                    {
                                        if (m_trailing_text)
                                        {
                                            warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                                            showLine(in, pos);
                                        }
                                    }
                                    else if (m_invalid_texture_coordinate)
                                    {
                                        errorWithCount(m_invalid_texture_coordinate_count) << "reading forth texture cordinate: \"" << trailing << "\"" << std::endl;
                                        showLine(in);
                                    }
                                }
                            }
                        }
                        else
                        {
                            if (isWhitespace(trailing))
                            {
                                if (m_trailing_text)
                                {
                                    warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                                    showLine(in, pos);
                                }
                            }
                            else if (m_invalid_texture_coordinate)
                            {
                                error() << "reading third texture cordinate: \"" << trailing << "\"" << std::endl;
                                showLine(in);
                            }
                        }
                    }
                }
                else
                {
                    if (isWhitespace(trailing))
                    {
                        if (m_trailing_text)
                        {
                            warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                            showLine(in, pos);
                        }
                    }
                    else if (m_invalid_texture_coordinate)
                    {
                        error() << "reading second texture cordinate: \"" << trailing << "\"" << std::endl;
                        showLine(in);
                    }
                }
            }
        }
    }
    else if (m_invalid_texture_coordinate)
    {
        error() << "reading texture coordinate" << std::endl;
        showLine(in);
        return false;
    }

    return true;
}

void AC3D::writeRef(std::ostream &out, const AC3D::Ref &ref) const
{
    out << ref.index;
    for (const auto &coord : ref.coordinates)
        out << ' ' << coord;
    out << newline(m_crlf);
}

bool AC3D::readSurface(std::istream &in, Surface &surface, Object &object, bool get_line)
{
    if (get_line)
    {
        if (!getLine(in))
            return false;
    }

    surface.line_number = m_line_number;
    surface.line_pos = m_line_pos;

    std::istringstream iss(m_line);
    std::string token;

    iss >> token;

    if (token == SURF_token)
    {
        iss >> std::ws;
        const std::streampos pos = iss.tellg();
        iss >> std::hex >> surface.flags >> std::dec;

        if (iss)
        {
            if (m_invalid_surface_type && !surface.isValidFlags(m_is_ac))
            {
                error() << "invalid surface type" << std::endl;
                showLine(iss, pos);
            }

            checkTrailing(iss);
        }
        else
        {
            error() << "reading type" << std::endl;
            showLine(iss, pos);
        }

        if (!getLine(in))
        {
            error() << "invalid surface" << std::endl;
            return true;
        }
        iss.clear();
        iss.str(m_line);
        iss >> token;
    }
    else if (token == kids_token)
    {
        error() << "less surfaces than specified" << std::endl;
        showLine(iss, 0);
        note(object.numsurf.line_number) << "number specified" << std::endl;
        showLine(in, object.numsurf.line_pos, object.numsurf.number_offset);
        ungetLine(in);
        return false;
    }
    else
    {
        error() << "invalid surface" << std::endl;
        showLine(iss, 0);
        return true;
    }

    if (token == mat_token)
    {
        size_t mat = 0;

        iss >> std::ws;
        const std::streampos pos = iss.tellg();
        iss >> mat;

        if (iss)
        {
            setMaterialUsed(mat);

            if (mat >= m_materials.size())
            {
                if (m_invalid_material_index)
                {
                    error() << "invalid material index: " << mat << " of "
                            << m_materials.size() << std::endl;
                    showLine(iss, pos);
                }
            }

            surface.mats.emplace_back(m_line_number, m_line_pos, mat);

            checkTrailing(iss);
        }
        else
        {
            error() << "reading material index" << std::endl;
            showLine(iss);
        }

        if (!getLine(in))
        {
            error() << "invalid surface" << std::endl;
            return true;
        }
        iss.clear();
        iss.str(m_line);
        iss >> token;
    }

    if (token == refs_token)
    {
        surface.refs.line_number = m_line_number;
        surface.refs.line_pos = m_line_pos;

        iss >> surface.refs.declared_size;

        if (iss)
            checkTrailing(iss);
        else
        {
            error() << "reading refs count" << std::endl;
            showLine(iss);
        }

        for (int j = 0; j < surface.refs.declared_size; ++j)
        {
            if (getLine(in))
            {
                Ref ref;

                std::istringstream iss1(m_line);

                if (readRef(iss1, ref))
                {
                    if (ref.index >= object.vertices.size())
                    {
                        if (m_invalid_vertex_index)
                        {
                            errorWithCount(m_invalid_vertex_index_count) << "invalid vertex index: " << ref.index << " of "
                                    << object.vertices.size() << std::endl;
                            showLine(iss1, 0);
                        }
                    }
                    else
                        object.vertices[ref.index].used = true;
                }
                const size_t valid_textures = object.getTexturesSize();
                if (ref.coordinates.size() < valid_textures)
                {
                    if (m_missing_uv_coordinates)
                    {
                        warningWithCount(m_missing_uv_coordinates_count) << "missing uv coordinates: "
                            << ref.coordinates.size() << " coordinate" << (ref.coordinates.size() != 1 ? "s" : "") << " "
                            << valid_textures << " texture" << (valid_textures != 1 ? "s" : "") << std::endl;
                        showLine(iss1, iss1.str().size() + 1);
                    }
                }
                if (ref.coordinates.size() > 1 && ref.coordinates.size() > valid_textures)
                {
                    if (m_extra_uv_coordinates)
                    {
                        warningWithCount(m_extra_uv_coordinates_count) << "extra uv coordinates: "
                            << ref.coordinates.size() << " coordinates "
                            << valid_textures << " texture" << (valid_textures != 1 ? "s" : "") << std::endl;
                        showLine(iss1, offsetOfToken(iss1, valid_textures * 2 + 1));
                    }
                }

                surface.refs.push_back(ref);
            }
        }

        surface.setTriangleStrip(object);

        checkDuplicateSurfaceVertices(in, object, surface);
        checkCollinearSurfaceVertices(in, object, surface);
        checkSurfaceCoplanar(in, object, surface);
        checkSurfacePolygonType(in, object, surface);
        checkSurfaceSelfIntersecting(in, object, surface);
        checkSurfaceStripHole(in, object, surface);
        checkSurfaceStripSize(in, object, surface);
        checkSurfaceStripDegenerate(in, object, surface);
        checkSurfaceStripDuplicateTriangles(in, object, surface);
        checkSurfaceNoTexture(in, object, surface);
        checkSurface2SidedOpaque(in, object, surface);
    }
    else
    {
        error() << "invalid surface" << std::endl;
        return false;
    }

    return true;
}

void AC3D::writeSurface(std::ostream &out, const Surface &surface) const
{
    out << "SURF 0x" << std::hex << surface.flags << std::dec << newline(m_crlf);
    if (!surface.mats.empty())
        out << "mat " << surface.mats[0].mat << newline(m_crlf);
    out << "refs " << surface.refs.size() << newline(m_crlf);
    for (const auto &ref : surface.refs)
        writeRef(out, ref);
}

void  AC3D::writeSurfaces(std::ostream &out, const Object &object) const
{
    if (!object.surfaces.empty())
    {
        out << "numsurf " << object.surfaces.size() << newline(m_crlf);
        for (const auto& surface : object.surfaces)
            writeSurface(out, surface);
    }
}

void AC3D::writeVertices(std::ostream &out, const Object &object) const
{
    if (!object.vertices.empty())
    {
        out << "numvert " << object.vertices.size() << newline(m_crlf);
        for (const auto& vertex : object.vertices)
        {
            out << vertex.vertex;
            if (vertex.has_normal)
                out << ' ' << vertex.normal;
            out << newline(m_crlf);
        }
    }
}

void AC3D::convertObjectsToAc(std::vector<Object> &objects)
{
    for (auto &object : objects)
    {
        convertObjectToAc(object);
        convertObjectsToAc(object.kids);
    }
}

void AC3D::convertObjectToAc(Object &object)
{
    std::vector<Surface> surfaces;

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        if (!object.surfaces[i].isTriangleStrip())
            surfaces.push_back(object.surfaces[i]);
        else
        {
            for (size_t j = 0; j < object.surfaces[i].refs.size() - 2; ++j)
            {
                if (object.surfaces[i].refs[j].index >= object.vertices.size() ||
                    object.surfaces[i].refs[j + 1].index >= object.vertices.size() ||
                    object.surfaces[i].refs[j + 2].index >= object.vertices.size())
                    continue;

                if (object.vertices[object.surfaces[i].refs[j].index].vertex == object.vertices[object.surfaces[i].refs[j + 1].index].vertex ||
                    object.vertices[object.surfaces[i].refs[j].index].vertex == object.vertices[object.surfaces[i].refs[j + 2].index].vertex ||
                    object.vertices[object.surfaces[i].refs[j + 1].index].vertex == object.vertices[object.surfaces[i].refs[j + 2].index].vertex)
                    continue;

                Surface surface;
                surface.mats = object.surfaces[i].mats;
                surface.flags = object.surfaces[i].flags & Surface::FaceMask;

                if ((j & 1U) == 0)
                {
                    Ref ref1;
                    ref1.index = object.surfaces[i].refs[j].index;
                    ref1.coordinates.push_back(object.surfaces[i].refs[j].coordinates.front());
                    surface.refs.push_back(ref1);

                    Ref ref2;
                    ref2.index = object.surfaces[i].refs[j + 1].index;
                    ref2.coordinates.push_back(object.surfaces[i].refs[j + 1].coordinates.front());
                    surface.refs.push_back(ref2);
                }
                else
                {
                    Ref ref1;
                    ref1.index = object.surfaces[i].refs[j + 1].index;
                    ref1.coordinates.push_back(object.surfaces[i].refs[j + 1].coordinates.front());
                    surface.refs.push_back(ref1);

                    Ref ref2;
                    ref2.index = object.surfaces[i].refs[j].index;
                    ref2.coordinates.push_back(object.surfaces[i].refs[j].coordinates.front());
                    surface.refs.push_back(ref2);
                }

                Ref ref3;
                ref3.index = object.surfaces[i].refs[j + 2].index;
                ref3.coordinates.push_back(object.surfaces[i].refs[j + 2].coordinates.front());
                surface.refs.push_back(ref3);

                surfaces.push_back(surface);
            }
        }
    }

    object.surfaces.clear();
    object.surfaces = surfaces;

    // remove textures
    if (object.textures.size() > 1)
        object.textures.resize(1);

    // remove texture type
    if (!object.textures.empty())
        object.textures[0].type.clear();

    // remove normals
    for (auto &vertex : object.vertices)
        vertex.has_normal = false;

    // removing normals on vertices can create duplicate vertices
    cleanVertices(object);
    cleanSurfaces(object);
}

void AC3D::convertObjectsToAcc(std::vector<Object> &objects)
{
    for (auto &object : objects)
    {
        if (object.type.type == "poly")
            convertObjectToAcc(object);
        else
            convertObjectsToAcc(object.kids);
    }
}

void AC3D::convertObjectToAcc(Object &object)
{
    struct Triangle
    {
        Triangle() = delete;
        Triangle(unsigned int flags, size_t mat,
            const Point3 &v0, const Point3 &v1, const Point3 &v2,
            const std::vector<Point2> &uv0, const std::vector<Point2> &uv1, const std::vector<Point2> &uv2)
            : m_flags(flags), m_mat(mat)
        {
            m_vertices[0] = v0;
            m_vertices[1] = v1;
            m_vertices[2] = v2;
            m_coordinates[0] = uv0;
            m_coordinates[1] = uv1;
            m_coordinates[2] = uv2;
            if (isFlatShaded())
            {
                m_normal = normalizedNormal(v0, v1, v2);
                m_normals[0].push_back(m_normal);
                m_normals[1].push_back(m_normal);
                m_normals[2].push_back(m_normal);
            }
            else
            {
                m_normal = unnormalizedNormal(v0, v1, v2);
                const double a1 = (v1 - v0).angleRadians(v2 - v0);
                const double a2 = (v2 - v1).angleRadians(v0 - v1);
                const double a3 = (v0 - v2).angleRadians(v1 - v2);

                m_normals[0].push_back(m_normal * a1);
                m_normals[1].push_back(m_normal * a2);
                m_normals[2].push_back(m_normal * a3);
            }
        }
        bool isFlatShaded() const
        {
            return (m_flags & Surface::ShadeMask) == 0;
        }
        bool isSmoothShaded() const
        {
            return (m_flags & Surface::ShadeMask) == Surface::Shaded;
        }
        bool good() const
        {
            return m_vertices[0] != m_vertices[1] && m_vertices[0] != m_vertices[2] && m_vertices[1] != m_vertices[2];
        }
        void smooth(Triangle &other)
        {
            for (size_t i = 0; i < 3; i++)
            {
                for (size_t j = 0; j < 3; j++)
                {
                    if (m_vertices[i] == other.m_vertices[j])
                    {
                        m_normals[i].emplace_back(other.m_normals[j][0]);
                        other.m_normals[j].emplace_back(m_normals[i][0]);
                    }
                }
            }
        }
        Vertex vertex(size_t index, const Object &object) const
        {
            Vertex  vertex;
            vertex.has_normal = true;
            vertex.vertex = m_vertices[index];
            vertex.normal = m_normals[index][0];
            for (size_t i = 1; i < m_normals[index].size(); i++)
            {
                const double angle = vertex.normal.angleDegrees(m_normals[index][i]);
                if (!object.creases.empty() && angle < object.creases[0].crease)
                    vertex.normal += m_normals[index][i];
                else if (object.creases.empty() && angle < 179.999)
                    vertex.normal += m_normals[index][i];
            }
            vertex.normal.normalize();
            return vertex;
        }

        Point3 m_vertices[3];
        std::vector<Point2> m_coordinates[3];
        std::vector<Point3> m_normals[3];
        Point3 m_normal;
        unsigned int m_flags;
        size_t m_mat;
        size_t m_vertex_index[3]{ 0, 0, 0 };
    };

    std::vector<Triangle> triangles;

    for (auto &surface : object.surfaces)
    {
        if (surface.isPolygon())
        {
            if (surface.refs.size() > 3)
            {
                if (surface.concave)
                {
                    // TODO
                    return;
                }
                else // triangle fan
                {
                    for (size_t i = 2; i < static_cast<size_t>(surface.refs.size()); i++)
                    {
                        const Triangle triangle(surface.flags, surface.mats[0].mat,
                            object.vertices[surface.refs[0].index].vertex,
                            object.vertices[surface.refs[i - 1].index].vertex,
                            object.vertices[surface.refs[i].index].vertex,
                            surface.refs[0].coordinates,
                            surface.refs[i - 1].coordinates,
                            surface.refs[i].coordinates);
                        if (triangle.good())
                            triangles.emplace_back(triangle);
                    }
                }
            }
            else
            {
                const Triangle triangle(surface.flags, surface.mats[0].mat,
                    object.vertices[surface.refs[0].index].vertex,
                    object.vertices[surface.refs[1].index].vertex,
                    object.vertices[surface.refs[2].index].vertex,
                    surface.refs[0].coordinates,
                    surface.refs[1].coordinates,
                    surface.refs[2].coordinates);
                if (triangle.good())
                    triangles.emplace_back(triangle);
            }
        }
    }

    if (triangles.empty())
        return;

    const size_t size = triangles.size();
    for (size_t i = 0, end = size - 1; i < end; i++)
    {
        for (size_t j = i + 1; j < size; j++)
        {
            if (triangles[i].isSmoothShaded() && triangles[j].isSmoothShaded())
                triangles[i].smooth(triangles[j]);
        }
    }

    std::vector<Vertex> vertices;

    for (auto &triangle : triangles)
    {
        for (size_t i = 0; i < 3; i++)
        {
            bool found = false;
            const Vertex vertex = triangle.vertex(i, object);
            for (size_t j = 0; j < vertices.size(); j++)
            {
                if (vertices[j] == vertex)
                {
                    triangle.m_vertex_index[i] = j;
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                triangle.m_vertex_index[i] = vertices.size();
                vertices.emplace_back(vertex);
            }
        }
    }

    object.vertices.clear();
    object.vertices = vertices;

    object.surfaces.clear();
    for (auto &triangle : triangles)
    {
        Surface surface;
        surface.flags = triangle.m_flags;
        surface.mats.emplace_back(triangle.m_mat);
        for (size_t i = 0; i < 3; i++)
        {
            Ref ref;
            ref.index = triangle.m_vertex_index[i];
            ref.coordinates = triangle.m_coordinates[i];
            surface.refs.emplace_back(ref);
        }
        object.surfaces.emplace_back(surface);
    }
}

bool AC3D::readHeader(std::istream &in)
{
    if (!getLine(in))
    {
        error(1) << "missing AC3D" << std::endl;
        return false;
    }

    const std::istringstream iss(m_line);

    // remove UTF-8 BOM
    if (m_line[0] == '\xef' && m_line[1] == '\xbb' && m_line[2] == '\xbf')
    {
        m_is_utf_8 = true;
        warning() << "found UTF-8 BOM" << std::endl;
        m_line.erase(0, 3);
    }
    else if (m_line[0] == '\xff' && m_line[1] == '\xfe')
    {
        if (m_line[2] == '\0' && m_line[3] == '\0')
        {
            error() << "found UTF-32 LE BOM" << std::endl;
            return false;
        }
        error() << "found UTF-16 LE BOM" << std::endl;
        return false;
    }
    else if (m_line[0] == '\xfe' && m_line[1] == '\xff')
    {
        error() << "found UTF-16 BE BOM" << std::endl;
        return false;
    }
    else if (m_line[0] == '\0' && m_line[1] == '\0' && m_line[2] == '\xfe' && m_line[3] == '\xff')
    {
        error() << "found UTF-32 BE BOM" << std::endl;
        return false;
    }

    if (m_line.compare(0, 4, "AC3D") != 0)
    {
        if (m_not_ac3d_file)
        {
            error(1) << "not AC3D file" << std::endl;
            showLine(iss, 0);
        }
        return false;
    }

    if (m_line.size() < 5)
    {
        error(1) << "missing AC3D version number" << std::endl;
        showLine(iss, 4);
        return false;
    }

    if (m_line[4] != 'b' && m_line[4] != 'c')
    {
        warning(1) << "unsupported version: " << m_line[4] << std::endl;
        showLine(iss, 4);
    }

    m_header.version = m_line.substr(0, 5);

    if (m_line.size() > 5)
    {
        if (m_trailing_text)
        {
            warningWithCount(m_trailing_text_count, 1) << "trailing text: \"" << m_line.substr(5) << "\"" << std::endl;
            showLine(iss, 5);
        }
    }

    return true;
}

void AC3D::writeHeader(std::ostream &out, const Header &header) const
{
    out << header.version << newline(m_crlf);
}

bool AC3D::readData(std::istringstream &iss, std::istream &in, std::string &data)
{
    size_t size = 0;

    iss >> size;

    if (iss)
    {
        checkTrailing(iss);

        if (size > 0)
        {
            std::getline(in, m_line);
            m_line_number++;
            data = m_line;
            if (data.back() == '\r') // remove DOS CR
                data.pop_back();

            while (data.size() < size)
            {
                data += '\n'; // add a newline removed by getline

                std::getline(in, m_line);
                m_line_number++;
                data += m_line;
                if (data.back() == '\r') // remove DOS CR
                    data.pop_back();
            }

            if (data.size() > size)
            {
                if (!(data.back() == '\r' && data.size() == (size + 1)))
                {
                    if (m_trailing_text)
                    {
                        warningWithCount(m_trailing_text_count) << "trailing text: \"" << data.substr(size) << "\"" << std::endl;
                        if (m_line.back() == '\r') // remove DOS CR
                            m_line.pop_back();
                        const std::istringstream iss1(m_line);
                        showLine(iss1, m_line.size() - (data.size() - size));
                    }
                    data.resize(size);
                }
                else
                    data.pop_back();
            }
        }
    }
    else
    {
        error() << "reading data size" << std::endl;
        showLine(iss);
        return false;
    }

    return true;
}

void AC3D::writeData(std::ostream &out, const std::string &data) const
{
    out << "data " << data.size() << newline(m_crlf);
    for (const char c : data)
    {
        if (c == '\n' && m_crlf)
            out << '\r';
        out << c;
    }
    out << newline(m_crlf);
}

bool AC3D::readColor(std::istringstream &in, Color &color, const std::string &expected, const std::string &next)
{
    bool status = true;
    for (auto & component : color)
    {
        in >> std::ws;

        std::streampos pos = in.tellg();
        double value = 0.0;

        in >> value;

        if (!in)
        {
            if (in.eof())
            {
                error() << "invalid " << expected << std::endl;
                showLine(in);
                return false;
            }

            in.clear();
            pos = in.tellg();
            std::string actual;
            in >> actual;
            if (in.eof())
            {
                error() << "invalid " << expected << std::endl;
                showLine(in);
                return false;
            }
            error() << "invalid " << expected << std::endl;
            showLine(in, pos);
            if (actual == next)
            {
                in.seekg(pos);
                return false;
            }
            status = false;
        }
        else if (value < 0.0 || value > 1.0)
        {
            if (m_invalid_material)
            {
                warningWithCount(m_invalid_material_count) << "invalid material " << expected << ": " << value << " range: 0 to 1" << std::endl;
                showLine(in, pos);
            }
        }

        component = value;
    }

    return status;
}

bool AC3D::readTypeAndColor(std::istringstream &in, Color &color, const std::string &expected, const std::string &next)
{
    in >> std::ws;

    const std::streampos pos = in.tellg();
    std::string actual;

    in >> actual;

    if (!in)
    {
        error() << "reading " << expected << std::endl;
        showLine(in);
        return false;
    }

    if (expected != actual)
    {
        std::istringstream iss(actual);
        double number = 0.0;
        iss >> number;
        if (iss)
        {
            error() << "reading " << expected << std::endl;
            showLine(in, pos);
            return readTypeAndColor(in, color, expected, next);
        }

        if (m_invalid_material)
        {
            warningWithCount(m_invalid_material_count) << "invalid material " << expected << ": " << actual << std::endl;
            showLine(in, pos);
        }
    }

    return readColor(in, color, expected, next);
}

bool AC3D::readValue(std::istringstream &in, double &value, const std::string &expected, double min, double max, bool is_float)
{
    in >> std::ws;
    const std::streampos pos = in.tellg();
    std::string value_string;
    in >> value_string;

    if (in)
    {
        std::istringstream iss(value_string);

        iss >> value;

        if (iss)
        {
            if (!is_float && value_string.find_first_of(".e") != std::string::npos)
            {
                if (m_floating_point)
                {
                    warningWithCount(m_floating_point_count) << "floating point " << expected << ": " << value_string << std::endl;
                    showLine(in, pos);
                }
            }

            if (value < min || value > max)
            {
                if (m_invalid_material)
                {
                    warningWithCount(m_invalid_material_count) << "invalid material " << expected << ": " << value << " range: "
                              << min << " to " << max << std::endl;
                    showLine(in, pos);
                }
            }
        }
        else
        {
            error() << "invalid " << expected << std::endl;
            showLine(in, pos);
            return false;
        }
    }
    else
    {
        error() << "invalid " << expected << std::endl;
        showLine(in);
        return false;
    }

    return true;
}

bool AC3D::readTypeAndValue(std::istringstream &in, double &value, const std::string &expected, const std::string &next, double min, double max, bool is_float)
{
    in >> std::ws;
    const std::streampos pos = in.tellg();
    std::string actual;

    in >> actual;

    if (!in)
    {
        error() << "reading " << expected << std::endl;
        showLine(in);
        return false;
    }

    if (actual != expected)
    {
        std::istringstream iss(actual);
        double number = 0.0;
        iss >> number;
        if (iss)
        {
            error() << "reading " << expected << std::endl;
            showLine(in, pos);
            return readTypeAndValue(in, value, expected, next, min, max, is_float);
        }

        if (m_invalid_material)
        {
            warningWithCount(m_invalid_material_count) << "invalid material " << expected << ": " << actual << std::endl;
            showLine(in, pos);
        }
    }

    return readValue(in, value, expected, min, max, is_float);
}

bool AC3D::readMaterial(std::istringstream &in, Material &material)
{
    material.line_number = m_line_number;
    material.line_pos = m_line_pos;

    in >> material.name;

    if (!in)
    {
        error() << "reading name" << std::endl;
        showLine(in);
        return false;
    }

    bool failed = readTypeAndColor(in, material.rgb, rgb_token, amb_token);

    if (!in.eof())
        failed |= readTypeAndColor(in, material.amb, amb_token, emis_token);

    if (!in.eof())
        failed |= readTypeAndColor(in, material.emis, emis_token, spec_token);

    if (!in.eof())
        failed |= readTypeAndColor(in, material.spec, spec_token, shi_token);

    if (!in.eof())
        failed |= readTypeAndValue(in, material.shi, shi_token, trans_token, 0, 128, false);

    if (!in.eof())
        failed = readTypeAndValue(in, material.trans, trans_token, empty_token, 0, 1, true);

    checkTrailing(in);

    return !failed;
}

bool AC3D::readMaterial(std::istringstream &first, std::istream &in, Material &material)
{
    material.line_number = m_line_number;
    material.line_pos = m_line_pos;
    material.version12 = true;

    bool has_rgb = false;
    bool has_amb = false;
    bool has_emis = false;
    bool has_spec = false;
    bool has_shi = false;
    bool has_trans = false;

    first >> material.name;

    while (getLine(in))
    {
        std::istringstream iss(m_line);
        std::string token;

        iss >> token;

        if (token == rgb_token)
        {
            has_rgb = true;
            readColor(iss, material.rgb, rgb_token, empty_token);
        }
        else if (token == amb_token)
        {
            has_amb = true;
            readColor(iss, material.amb, amb_token, empty_token);
        }
        else if (token == emis_token)
        {
            has_emis = true;
            readColor(iss, material.emis, emis_token, empty_token);
        }
        else if (token == spec_token)
        {
            has_spec = true;
            readColor(iss, material.spec, spec_token, empty_token);
        }
        else if (token == shi_token)
        {
            has_shi = true;
            readValue(iss, material.shi, shi_token, 0, 128, false);
        }
        else if (token == trans_token)
        {
            has_trans = true;
            readValue(iss, material.trans, trans_token, 0, 1, true);
        }
        else if (token == data_token)
        {
            Data data;
            data.line_number = m_line_number;
            data.line_pos = m_line_pos;

            if (readData(iss, in, data.data))
            {
                if (!material.data.empty())
                {
                    warning() << "multiple data" << std::endl;
                    showLine(iss, 0);
                    note(material.data.front().line_number) << "first instance" << std::endl;
                    showLine(in, material.data.front().line_pos);
                }

                material.data.push_back(data);
            }
        }
        else if (token == ENDMAT_token)
        {
            checkTrailing(iss);

            if (!has_rgb)
                warning() << "missing rgb" << std::endl;

            if (!has_amb)
                warning() << "missing amb" << std::endl;

            if (!has_emis)
                warning() << "missing emis" << std::endl;

            if (!has_spec)
                warning() << "missing spec" << std::endl;

            if (!has_shi)
                warning() << "missing shi" << std::endl;

            if (!has_trans)
                warning() << "missing trans" << std::endl;

            return true;
        }
        else
        {
            if (m_invalid_token)
                errorWithCount(m_invalid_token_count) << "invalid token: " << token << std::endl;
            return false;
        }

        if (iss)
            checkTrailing(iss);
        else
            warning() << "invalid " << token << std::endl;
    }

    return false;
}

void AC3D::writeMaterial(std::ostream &out, const Material &material) const
{
    if (!material.version12)
    {
        out << "MATERIAL " << material.name
            << " rgb " << material.rgb
            << "  amb " << material.amb
            << "  emis " << material.emis
            << "  spec " << material.spec
            << "  shi " << material.shi
            << "  trans " << material.trans << newline(m_crlf);
    }
    else
    {
        out << "MAT " << material.name << newline(m_crlf);
        out << "rgb " << material.rgb << newline(m_crlf);
        out << "amb " << material.amb << newline(m_crlf);
        out << "emis " << material.emis  << newline(m_crlf);
        out << "spec " << material.spec  << newline(m_crlf);
        out << "shi " << material.shi << newline(m_crlf);
        out << "trans " << material.trans << newline(m_crlf);
        for (const auto &data : material.data)
            writeData(out, data.data);
        out << "ENDMAT" << newline(m_crlf);
    }
}

bool icasecmp(const std::string &l, const std::string &r)
{
    return l.size() == r.size() &&
           equal(l.cbegin(), l.cend(), r.cbegin(),
                 [](std::string::value_type l1, std::string::value_type r1)
                 { return std::toupper(l1) == std::toupper(r1); });
}

bool AC3D::readObject(std::istringstream &iss, std::istream &in, Object &object)
{
    object.line_number = m_line_number;
    object.line_pos = m_line_pos;

    object.type.line_number = m_line_number;
    object.type.line_pos = m_line_pos;

    iss >> std::ws;
    object.type.type_offset = static_cast<int>(iss.tellg());
    iss >> object.type.type;

    if (!iss)
    {
        error() << "reading type" << std::endl;
        showLine(iss);
    }
    else
    {
        if (object.type.type == world_token)
        {
            if (m_multiple_world && m_has_world)
            {
                warningWithCount(m_multiple_world_count) << "multiple world" << std::endl;
                showLine(iss, object.type.type_offset);
            }

            m_has_world = true;
        }

        if (object.type.type != world_token && object.type.type != group_token &&
            object.type.type != poly_token && object.type.type != light_token)
        {
            if (icasecmp(object.type.type, world_token) || icasecmp(object.type.type, group_token) ||
                icasecmp(object.type.type, poly_token) || icasecmp(object.type.type, light_token))
            {
                warning() << "type should be lowercase: " << object.type.type << std::endl;
                showLine(iss, object.type.type_offset);
            }
            else
            {
                warning() << "unknown object type: " << object.type.type << std::endl;
                showLine(iss, object.type.type_offset);
            }
        }

        checkTrailing(iss);
    }

    while (getLine(in))
    {
        std::istringstream iss1(m_line);
        std::string token;

        iss1 >> token;

        if (token == name_token)
        {
            Name name;
            name.line_number = m_line_number;
            name.line_pos = m_line_pos;

            iss1 >> name.name;

            if (iss1)
            {
                if (!object.names.empty() && m_multiple_name)
                {
                    warningWithCount(m_multiple_name_count) << "multiple name" << std::endl;
                    showLine(iss1, 0);
                    note(object.names.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.names.front().line_pos);
                }

                object.names.push_back(name);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading name" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == data_token)
        {
            Data data;
            data.line_number = m_line_number;
            data.line_pos = m_line_pos;

            if (readData(iss1, in, data.data))
            {
                if (!object.data.empty())
                {
                    warning() << "multiple data" << std::endl;
                    showLine(iss1, 0);
                    note(object.data.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.data.front().line_pos);
                }

                object.data.push_back(data);
            }
        }
        else if (token == texture_token)
        {
            Texture texture;
            texture.line_number = m_line_number;
            texture.line_pos = m_line_pos;

            iss1 >> texture.name;

            if (iss1)
            {
                if (hasTrailing(iss1))
                {
                    if (m_is_ac)
                    {
                        if (m_trailing_text)
                        {
                            warningWithCount(m_trailing_text_count) << "trailing text: \"" << getTrailing(iss1) << "\"" << std::endl;
                            showLine(iss1);
                        }
                    }
                    else
                    {
                        iss1 >> texture.type;
                        if (iss1)
                        {
                            if (hasTrailing(iss1))
                            {
                                if (m_trailing_text)
                                {
                                    warningWithCount(m_trailing_text_count) << "trailing text: \"" << getTrailing(iss1) << "\"" << std::endl;
                                    showLine(iss1);
                                }
                            }
                        }
                        else
                        {
                            if (m_trailing_text)
                            {
                                warningWithCount(m_trailing_text_count) << "trailing text: \"" << getTrailing(iss1) << "\"" << std::endl;
                                showLine(iss1);
                            }
                        }
                    }
                }

                if (m_is_ac && !object.textures.empty() && m_multiple_texture)
                {
                    warningWithCount(m_multiple_texture_count) << "multiple texture" << std::endl;
                    showLine(iss1, 0);
                    note(object.textures.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.textures.front().line_pos);
                }

                if (texture.name != "empty_texture_no_mapping")
                {
                    const std::filesystem::path file_path(m_file);
                    std::string texture_name(texture.name);
                    std::filesystem::path texture_path(texture_name);
                    const bool absolute = texture_path.is_absolute() ||
                        (std::isalpha(texture_name[0]) != 0 && texture_name[1] == ':');

                    texture.path = texture.name;

                    // use parent path of file when available
                    // and texture path is not absolute
                    if (!file_path.parent_path().empty() && !absolute)
                    {
                        texture_path = file_path.parent_path().append(texture_name);

                        if (std::filesystem::exists(texture_path))
                            texture.path = texture_path.string();
                    }

                    if (!std::filesystem::exists(texture_path))
                    {
                        bool found = false;

                        if (!absolute) // don't search if absolute path
                        {
                            // look in alternate paths if available
                            for (const auto & path : m_texture_paths)
                            {
                                const std::filesystem::path new_path = std::filesystem::path(path).append(texture_name);
                                if (std::filesystem::exists(new_path))
                                {
                                    found = true;
                                    texture.path = new_path.string();
                                    break;
                                }
                            }
                        }

                        if (!found && m_missing_texture)
                        {
                            warningWithCount(m_missing_texture_count) << "missing texture: " << texture_path.generic_string() << std::endl;
                            showLine(iss1, 0);
                        }
                    }
                    else if (!absolute && !m_texture_paths.empty()) // look for duplicate textures
                    {
                        const std::size_t size = std::filesystem::file_size(texture_path);

                        for (const auto & path : m_texture_paths)
                        {
                            const std::filesystem::path other = std::filesystem::path(path).append(texture_name);
                            if (std::filesystem::exists(other))
                            {
                                if (texture.path.empty())
                                    texture.path = other.string();

                                if (size == std::filesystem::file_size(other))
                                {
                                    std::ifstream file1(texture_path, std::ifstream::binary);
                                    std::ifstream file2(other, std::ifstream::binary);
                                    if (file1.good() && file2.good())
                                    {
                                        if (std::equal(std::istreambuf_iterator<char>(file1),
                                                       std::istreambuf_iterator<char>(),
                                                       std::istreambuf_iterator<char>(file2)))
                                        {
                                            if (m_duplicate_texture)
                                            {
                                                warningWithCount(m_duplicate_texture_count) << "duplicate texture: " << texture_path
                                                          << " and " << other << std::endl;
                                                showLine(iss1, 0);
                                            }
                                        }
                                        else
                                        {
                                            if (m_ambiguous_texture)
                                            {
                                                warningWithCount(m_ambiguous_texture_count) << "ambiguous texture: " << texture_path
                                                          << " and " << other << std::endl;
                                                showLine(iss1, 0);
                                            }
                                        }
                                    }
                                }
                                else if (m_ambiguous_texture)
                                {
                                    warningWithCount(m_ambiguous_texture_count) << "ambiguous texture: " << texture_path
                                              << " and " << other << std::endl;
                                    showLine(iss1, 0);
                                }
                            }
                        }
                    }
                }

                object.textures.push_back(texture);
            }
            else
            {
                error() << "reading texture" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == texrep_token)
        {
            TexRep texrep;
            texrep.line_number = m_line_number;
            texrep.line_pos = m_line_pos;

            iss1 >> texrep.texrep;

            if (iss1)
            {
                if (!object.texreps.empty() && m_multiple_texrep)
                {
                    warningWithCount(m_multiple_texrep_count) << "multiple texrep" << std::endl;
                    showLine(iss1, 0);
                    note(object.texreps.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.texreps.front().line_pos);
                }

                object.texreps.push_back(texrep);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading texrep" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == texoff_token)
        {
            TexOff texoff;
            texoff.line_number = m_line_number;
            texoff.line_pos = m_line_pos;

            iss1 >> texoff.texoff;

            if (iss1)
            {
                if (!object.texoffs.empty() && m_multiple_texoff)
                {
                    warningWithCount(m_multiple_texoff_count) << "multiple texoff" << std::endl;
                    showLine(iss1, 0);
                    note(object.texoffs.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.texoffs.front().line_pos);
                }

                object.texoffs.push_back(texoff);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading texoff" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == subdiv_token)
        {
            SubDiv subdiv;
            subdiv.line_number = m_line_number;
            subdiv.line_pos = m_line_pos;

            iss1 >> subdiv.subdiv;

            if (iss1)
            {
                if (!object.subdivs.empty() && m_multiple_subdiv)
                {
                    warningWithCount(m_multiple_subdiv_count) << "multiple subdiv" << std::endl;
                    showLine(iss1, 0);
                    note(object.subdivs.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.subdivs.front().line_pos);
                }

                object.subdivs.push_back(subdiv);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading subdiv" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == crease_token)
        {
            Crease crease;
            crease.line_number = m_line_number;
            crease.line_pos = m_line_pos;

            iss1 >> crease.crease;

            if (iss1)
            {
                if (!object.creases.empty() && m_multiple_crease)
                {
                    warningWithCount(m_multiple_crease_count) << "multiple crease" << std::endl;
                    showLine(iss1, 0);
                    note(object.creases.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.creases.front().line_pos);
                }

                object.creases.push_back(crease);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading crease" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == rot_token)
        {
            Rotation rotation;
            rotation.line_number = m_line_number;
            rotation.line_pos = m_line_pos;

            iss1 >> rotation.rotation;

            if (iss1)
            {
                if (!object.rotations.empty() && m_multiple_rot)
                {
                    warningWithCount(m_multiple_rot_count) << "multiple rot" << std::endl;
                    showLine(iss1, 0);
                    note(object.rotations.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.rotations.front().line_pos);
                }

                object.rotations.push_back(rotation);
                object.matrix.setRotation(rotation.rotation);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading rot" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == loc_token)
        {
            Location location;
            location.line_number = m_line_number;
            location.line_pos = m_line_pos;

            iss1 >> location.location;

            if (iss1)
            {
                if (!object.locations.empty() && m_multiple_loc)
                {
                    warningWithCount(m_multiple_loc_count) << "multiple loc" << std::endl;
                    showLine(iss1, 0);
                    note(object.locations.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.locations.front().line_pos);
                }

                object.locations.push_back(location);
                object.matrix.setLocation(location.location);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading loc" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == url_token)
        {
            URL url;
            url.line_number = m_line_number;
            url.line_pos = m_line_pos;

            iss1 >> url.url;

            if (iss1)
            {
                if (!object.urls.empty())
                {
                    warning() << "multiple url" << std::endl;
                    showLine(iss1, 0);
                    note(object.urls.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.urls.front().line_pos);
                }

                object.urls.push_back(url);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading url" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == locked_token)
        {
            const LineInfo info(m_line_number, m_line_pos);

            if (!object.locked.empty() && m_multiple_locked)
            {
                warningWithCount(m_multiple_locked_count) << "multiple locked" << std::endl;
                showLine(iss1, 0);
                note(object.locked.front().line_number) << "first instance" << std::endl;
                showLine(in, object.locked.front().line_pos);
            }

            object.locked.push_back(info);

            checkTrailing(iss1);
        }
        else if (token == hidden_token)
        {
            const LineInfo info(m_line_number, m_line_pos);

            if (!object.hidden.empty() && m_multiple_hidden)
            {
                warningWithCount(m_multiple_hidden_count) << "multiple hidden" << std::endl;
                showLine(iss1, 0);
                note(object.hidden.front().line_number) << "first instance" << std::endl;
                showLine(in, object.hidden.front().line_pos);
            }

            object.hidden.push_back(info);

            checkTrailing(iss1);
        }
        else if (token == folded_token)
        {
            const LineInfo info(m_line_number, m_line_pos);

            if (!object.folded.empty() && m_multiple_folded)
            {
                warningWithCount(m_multiple_folded_count) << "multiple folded" << std::endl;
                showLine(iss1, 0);
                note(object.folded.front().line_number) << "first instance" << std::endl;
                showLine(in, object.folded.front().line_pos);
            }

            object.folded.push_back(info);

            checkTrailing(iss1);
        }
        else if (token == numvert_token)
        {
            object.numvert.line_number = m_line_number;
            object.numvert.line_pos = m_line_pos;

            iss1 >> std::ws;
            object.numvert.number_offset = static_cast<int>(iss1.tellg());
            iss1 >> object.numvert.number;

            if (iss1)
                checkTrailing(iss1);
            else
            {
                error() << "reading number of verticies" << std::endl;
                showLine(iss1);
                continue;
            }

            for (int i = 0; i < object.numvert.number; ++i)
            {
                if (getLine(in))
                {
                    Vertex vertex;

                    vertex.line_number = m_line_number;
                    vertex.line_pos = m_line_pos;

                    std::istringstream iss2(m_line);

                    iss2 >> vertex.vertex;

                    if (iss2)
                    {
                        if (hasTrailing(iss2))
                        {
                            const std::streampos pos2 = iss2.tellg();
                            const std::string trailing = getTrailing(iss2);
                            if (m_is_ac)
                            {
                                if (m_trailing_text)
                                {
                                    warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                                    showLine(iss2, pos2);
                                }
                            }
                            else
                            {
                                Point3 normal{ std::numeric_limits<double>::quiet_NaN(),
                                               std::numeric_limits<double>::quiet_NaN(),
                                               std::numeric_limits<double>::quiet_NaN() };
                                iss2 >> normal;
                                if (iss2)
                                {
                                    vertex.normal = normal;
                                    vertex.has_normal = true;

                                    if (m_invalid_normal_length)
                                    {
                                        const double length = vertex.normal.length();
                                        // assume truncated float values
                                        constexpr double epsilon = static_cast<double>(std::numeric_limits<float>::epsilon()) * 10;

                                        if (std::fabs(1 - length) > epsilon)
                                        {
                                            warningWithCount(m_invalid_normal_length_count) << "invalid normal length: " << length
                                                      << " should be 1" << std::endl;
                                            // find start of normal
                                            size_t offset = pos2;
                                            while (offset < m_line.size() && std::isspace(m_line[offset]) != 0)
                                                offset++;
                                            showLine(iss2, offset);
                                        }
                                    }

                                    checkTrailing(iss2);
                                }
                                else
                                {
                                    if (isWhitespace(trailing))
                                    {
                                        if (m_trailing_text)
                                            warningWithCount(m_trailing_text_count) << "trailing text: \"" << trailing << "\"" << std::endl;
                                    }
                                    else if (m_invalid_normal)
                                    {
                                        errorWithCount(m_invalid_normal_count) << "reading normal" << std::endl;
                                        showLine(iss2);
                                    }
                                }
                            }
                        }
                        else
                        {
                            if (m_is_ac == false)
                            {
                                if (m_missing_normal)
                                {
                                    warningWithCount(m_missing_normal_count) << "missing normal" << std::endl;
                                    showLine(iss2, m_line.size() + 1);
                                }
                            }
                        }
                    }
                    else
                    {
                        const std::streampos pos1 = iss2.tellg();
                        iss2.clear();
                        iss2.seekg(0, std::ios::beg);
                        std::string token1;
                        iss2 >> token1;
                        if (token1 == numsurf_token || token1 == kids_token)
                        {
                            if (m_missing_vertex)
                            {
                                errorWithCount(m_missing_vertex_count) << "missing vertex" << std::endl;
                                showLine(iss2, 0);
                                ungetLine(in);
                                break;
                            }
                        }

                        error() << "reading vertex" << std::endl;
                        showLine(iss2, pos1 == -1 ? static_cast<std::streampos>(0) : pos1);
                    }

                    object.vertices.push_back(vertex);
                }
            }

            checkDuplicateVertices(in, object);
        }
        else if (token == numsurf_token)
        {
            object.numsurf.line_number = m_line_number;
            object.numsurf.line_pos = m_line_pos;

            iss1 >> std::ws;
            object.numsurf.number_offset = static_cast<int>(iss1.tellg());
            iss1 >> object.numsurf.number;

            if (!iss1 || object.numsurf.number < 0)
            {
                if (m_invalid_number_of_surfaces)
                {
                    errorWithCount(m_invalid_number_of_surfaces_count) << "invalid number of surfaces" << std::endl;
                    showLine(iss1);
                }
                continue;
            }

            checkTrailing(iss1);

            for (int i = 0; i < object.numsurf.number; ++i)
            {
                Surface surface;

                if (!readSurface(in, surface, object, true))
                    break;

                object.surfaces.push_back(surface);
            }
        }
        else if (token == kids_token)
        {
            int kids = 0;

            iss1 >> kids;

            if (!iss1)
            {
                error() << "reading kids count" << std::endl;
                continue;
            }

            checkTrailing(iss1);

            if (kids > 0)
            {
                m_level++;
                const size_t kids_line = m_line_number;

                for (int i = 0; i < kids; ++i)
                {
                    if (getLine(in))
                    {
                        std::istringstream iss2(m_line);
                        std::string token1;

                        iss2 >> token1;

                        if (token1 == OBJECT_token)
                        {
                            Object kid;
                            readObject(iss2, in, kid);
                            object.kids.push_back(kid);
                        }
                        else if (m_invalid_token)
                        {
                            errorWithCount(m_invalid_token_count) << "invalid token: " << token1 << std::endl;
                            showLine(iss2, 0);
                        }
                    }
                    else
                    {
                        if (m_missing_kids)
                            warningWithCount(m_missing_kids_count, kids_line) << "missing kids: only " << i << " out of " << kids << " kids found" << std::endl;
                        return false;
                    }
                }
                m_level--;
            }
            break;
        }
        else if (!m_is_ac && token == shader_token)
        {
            Shader shader;
            shader.line_number = m_line_number;
            shader.line_pos = m_line_pos;

            iss1 >> shader.name;

            if (iss1)
            {
                if (!object.shaders.empty())
                {
                    warning() << "multiple shaders" << std::endl;
                    showLine(iss1, 0);
                    note(object.shaders.front().line_number) << "first instance" << std::endl;
                    showLine(in, object.shaders.front().line_pos);
                }

                object.shaders.push_back(shader);

                checkTrailing(iss1);
            }
            else
            {
                error() << "reading shader" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == MATERIAL_token)
        {
            warning() << "MATERIAL should come before OBJECT" << std::endl;
            showLine(iss1, 0);
            Material material;
            readMaterial(iss1, material);
            m_materials.push_back(material);
        }
        else if (token == MAT_token && m_header.getVersion() == 12)
        {
            warning() << "MAT should come before OBJECT" << std::endl;
            showLine(iss1, 0);
            Material material;
            readMaterial(iss1, in, material);
            m_materials.push_back(material);
        }
        else if (token == SURF_token)
        {
            error() << "found more SURF than specified" << std::endl;
            showLine(iss1, 0);
            note(object.numsurf.line_number) << "number specified" << std::endl;
            showLine(in, object.numsurf.line_pos, object.numsurf.number_offset);

            Surface surface;

            if (readSurface(in, surface, object, false))
                object.surfaces.push_back(surface);
        }
        else if (m_invalid_token)
        {
            errorWithCount(m_invalid_token_count) << "invalid token: " << token << std::endl;
            showLine(iss1, 0);
        }
    }

    if (object.empty() && m_empty_object)
    {
        warningWithCount(m_empty_object_count, object.line_number) << "empty object: "
                                    << (!object.names.empty() ? object.names.back().name.c_str() : "")
                                    << std::endl;
        showLine(iss, 0);
    }

    checkUnusedVertex(in, object);
    checkMissingSurfaces(in, object);
    checkDuplicateSurfaces(in, object);
    checkDifferentUV(in, object);
    checkGroupWithGeometry(in, object);
    checkDifferentSURF(in, object);
    checkDifferentMat(in, object);
    checkDuplicateTriangles(in, object);

    return true;
}

bool AC3D::Object::sameSurface(size_t index1, size_t index2, Difference difference) const
{
    const Surface &surface1 = surfaces[index1];
    const Surface &surface2 = surfaces[index2];

    if (surface1.refs.size() != surface2.refs.size() || surface1.refs.empty())
        return false;

    const size_t size = surface1.refs.size();

    if (difference == Difference::None)
    {
        for (size_t i = 0; i < size; ++i)
        {
            const size_t vertex1 = surface1.refs[i].index;
            const size_t vertex2 = surface2.refs[i].index;

            // skip invalid vertex
            if (vertex1 >= vertices.size() || vertex2 >= vertices.size())
                break;

            if (!(vertex1 == vertex2 || vertices[vertex1] == vertices[vertex2]))
                return false;
        }

        return true;
    }

    if (difference == Difference::Order)
    {
        for (size_t i = 0; i < size; ++i)
        {
            const size_t vertex1 = surface1.refs[i].index;

            for (size_t j = 0; j < size; j++)
            {
                const size_t vertex2 = surface2.refs[j].index;

                if (sameVertex(vertex1, vertex2))
                {
                    bool same = true;
                    for (size_t k = 1; k < size; k++)
                    {
                        if (!sameVertex(surface1.refs[(i + k) % size].index, surface2.refs[(j + k) % size].index))
                        {
                            same = false;
                            break;
                        }
                    }
                    if (same)
                        return true;
                }
            }
        }
        return false;
    }

    if (difference == Difference::Winding)
    {
        for (size_t i = 0; i < size; ++i)
        {
            const size_t vertex1 = surface1.refs[i].index;

            for (size_t j = 0; j < size; j++)
            {
                const size_t vertex2 = surface2.refs[j].index;

                if (sameVertex(vertex1, vertex2))
                {
                    bool same = true;
                    for (size_t k = 1; k < size; k++)
                    {
                        if (!sameVertex(surface1.refs[(i + k) % size].index, surface2.refs[(j + size - k) % size].index))
                        {
                            same = false;
                            break;
                        }
                    }
                    if (same)
                        return true;
                }
            }
        }

        return false;
    }

    return false;
}

void AC3D::Object::removeKids(const RemoveInfo &remove_info)
{
    auto kid = kids.begin();
    while (kid != kids.end())
    {
        if (!kid->names.empty() && kid->type.type == remove_info.object_type && regex_match(kid->names[0].name, remove_info.regular_expression))
            kid = kids.erase(kid);
        else
        {
            kid->removeKids(remove_info);
            kid++;
        }
    }
}

void AC3D::Object::dump(DumpType dump_type, size_t count, size_t level) const
{
    std::string indent;

    for (size_t i = 0; i < level; i++)
        indent += "    ";

    if (type.type == "world")
    {
        std::cout << indent << (count + 1) << " " << type.type;
        std::cout << " " << kids.size() << " kid" << (kids.size() == 1 ? "" : "s") << std::endl;
    }
    else
    {
        if (type.type == "group")
        {
            std::cout << indent << (count + 1) << " " << type.type;

            for (const auto& name : names)
                std::cout << " " << name.name;

            std::cout << " " << kids.size() << " kid" << (kids.size() == 1 ? "" : "s") << std::endl;
        }
        else if (type.type == "poly" && (dump_type == DumpType::poly || dump_type == DumpType::surf))
        {
            std::cout << indent << (count + 1) << " " << type.type;

            for (const auto& name : names)
                std::cout << " " << name.name;

            if (!textures.empty())
            {
                std::cout << " texture";

                for (const auto& texture : textures)
                    std::cout << " " << texture.name;
            }

            std::cout << " " << vertices.size() << " vertices";
            std::cout << " " << surfaces.size() << " surface" << (surfaces.size() == 1 ? "" : "s") << std::endl;

            if (dump_type == DumpType::surf)
            {
                for (size_t i = 0; i < surfaces.size(); i++)
                {
                    surfaces[i].dump(dump_type, i, level + 1);
                }
            }
        }
    }

    for (size_t i = 0; i < kids.size(); i++)
    {
        kids[i].dump(dump_type, i, level + 1);
    }
}

void AC3D::Surface::dump(DumpType dump_type, size_t count, size_t level) const
{
    for (size_t i = 0; i < level; i++)
        std::cout << "    ";

    std::cout << (count + 1) << " surface flags 0x" << std::hex << flags << std::dec;

    if (!mats.empty())
    {
        std::cout << " mat";

        for (const auto &mat : mats)
            std::cout << " " << mat.mat;
    }

    std::cout << " " << refs.size() << " ref" << (refs.size() == 1 ? "" : "s") << std::endl;
}

void AC3D::Surface::setTriangleStrip(const Object &object)
{
    // TODO: Should we handle this being called more than once?
    if (triangleStrip.empty() && isTriangleStrip())
    {
        for (size_t i = 2; i < refs.size(); i++)
        {
            if ((i & 1u) == 0)
            {
                triangleStrip.emplace_back(object.vertices[refs[i - 2].index],
                                           object.vertices[refs[i - 1].index],
                                           object.vertices[refs[i].index],
                                           refs[i - 2], refs[i - 1], refs[i]);
            }
            else // reverse winding to match drawing order
            {
                triangleStrip.emplace_back(object.vertices[refs[i - 1].index],
                                           object.vertices[refs[i - 2].index],
                                           object.vertices[refs[i].index],
                                           refs[i - 1], refs[i - 2], refs[i]);
            }
        }
    }
}

void AC3D::writeObject(std::ostream &out, const Object &object) const
{
    out << "OBJECT " << object.type.type << newline(m_crlf);
    if (!object.names.empty())
        out << "name " << object.names.back().name << newline(m_crlf);
    if (!object.urls.empty())
        out << "url " << object.urls.back().url << newline(m_crlf);
    if (!object.locations.empty())
        out << "loc " << object.locations.back().location << newline(m_crlf);
    if (!object.rotations.empty())
        out << "rot " << object.rotations.back().rotation << newline(m_crlf);
    if (!object.creases.empty())
        out << "crease " << object.creases.back().crease << newline(m_crlf);
    if (!object.hidden.empty())
        out << "hidden" << newline(m_crlf);
    if (!object.locked.empty())
        out << "locked" << newline(m_crlf);
    if (!object.folded.empty())
        out << "folded" << newline(m_crlf);
    for (const auto &data : object.data)
        writeData(out, data.data);
    for (const auto &shader : object.shaders)
        out << "shader " << shader.name << newline(m_crlf);
    for (const auto &texture : object.textures)
    {
        out << "texture " << texture.name;
        if (!texture.type.empty())
            out << ' ' << texture.type;
        out << newline(m_crlf);
    }
    if (!object.texreps.empty())
        out << "texrep " << object.texreps.back().texrep << newline(m_crlf);
    if (!object.texoffs.empty())
        out << "texoff " << object.texoffs.back().texoff << newline(m_crlf);
    if (!object.subdivs.empty())
        out << "subdiv " << object.subdivs.back().subdiv << newline(m_crlf);
    writeVertices(out, object);
    writeSurfaces(out, object);

    out << "kids " << object.kids.size() << newline(m_crlf);
    for (const auto &kid : object.kids)
        writeObject(out, kid);
}

bool AC3D::read(const std::string &file)
{
    m_file = file;
    m_line_number = 0;
    m_level = 0;
    m_errors = 0;
    m_warnings = 0;
    m_crlf = false;

    m_materials.clear();
    m_objects.clear();

    const std::string extension = std::filesystem::path(file).extension().string();

    if (extension == ".ac")
        m_is_ac = true;
    else if (extension == ".acc")
        m_is_ac = false;
    else
    {
        std::cerr << "Unknown file extension: \"" << extension << "\"" << std::endl;
        return false;
    }

    std::ifstream in(m_file, std::ifstream::binary);

    if (!in)
    {
        std::cerr << "Failed to read: \"" << m_file << "\"" << std::endl;
        return false;
    }

    if (!readHeader(in))
        return false;

    bool needMaterial = true;

    while (getLine(in))
    {
        std::istringstream iss(m_line);
        std::string token;

        iss >> token;

        if (needMaterial)
        {
            if (token == MATERIAL_token)
            {
                Material material;
                readMaterial(iss, material);
                m_materials.push_back(material);
            }
            else if (token == MAT_token && m_header.getVersion() == 12)
            {
                Material material;
                readMaterial(iss, in, material);
                m_materials.push_back(material);
            }
            else if (token == OBJECT_token)
            {
                if (m_extra_object && !m_objects.empty())
                {
                    warningWithCount(m_extra_object_count) << "extra OBJECT" << std::endl;
                    showLine(in, m_line_pos);
                }
                Object object;
                readObject(iss, in, object);
                needMaterial = false;
                m_objects.push_back(object);
            }
            else if (m_invalid_token)
            {
                errorWithCount(m_invalid_token_count) << "invalid token: " << token << std::endl;
                showLine(iss, 0);
            }
        }
        else if (token == OBJECT_token)
        {
            if (m_extra_object && !m_objects.empty())
            {
                warningWithCount(m_extra_object_count) << "extra OBJECT" << std::endl;
                showLine(in, m_line_pos);
            }
            Object object;
            readObject(iss, in, object);
            m_objects.push_back(object);
        }
        else if (token == MATERIAL_token)
        {
            warning() << "MATERIAL should come before OBJECT" << std::endl;
            showLine(iss, 0);
            Material material;
            readMaterial(iss, material);
            m_materials.push_back(material);
        }
        else if (token == MAT_token && m_header.getVersion() == 12)
        {
            warning() << "MAT should come before OBJECT" << std::endl;
            showLine(iss, 0);
            Material material;
            readMaterial(iss, in, material);
            m_materials.push_back(material);
        }
        else if (m_invalid_token)
        {
            errorWithCount(m_invalid_token_count) << "invalid token: " << token << std::endl;
            showLine(iss, 0);
        }
    }

    in.clear(); // clear eof so we can seek in file

    checkDuplicateMaterials(in);
    checkUnusedMaterial(in);

    checkOverlapping2SidedSurface(in);

    return true;
}

void AC3D::checkDuplicateMaterials(std::istream &in)
{
    if (!m_duplicate_materials)
        return;

    if (m_materials.size() > 1)
    {
        std::vector<bool> duplicates(m_materials.size(), false);

        for (size_t i = 0; i < m_materials.size(); ++i)
        {
            if (!duplicates[i])
            {
                for (size_t j = i + 1; j < m_materials.size(); ++j)
                {
                    if (sameMaterial(m_materials[i], m_materials[j]))
                    {
                        duplicates[j] = true;
                        warning(m_materials[j].line_number) << "duplicate materials" << std::endl;
                        showLine(in, m_materials[j].line_pos);
                        note(m_materials[i].line_number) << "first instance" << std::endl;
                        showLine(in, m_materials[i].line_pos);
                    }
                }
            }
        }

        duplicates.resize(duplicates.size(), false);

        for (size_t i = 0; i < m_materials.size(); ++i)
        {
            if (!duplicates[i])
            {
                for (size_t j = i + 1; j < m_materials.size(); ++j)
                {
                    if (m_materials[i].name != m_materials[j].name &&
                        sameMaterialParameters(m_materials[i], m_materials[j]))
                    {
                        duplicates[j] = true;
                        warning(m_materials[j].line_number)
                            << "duplicate materials with different names" << std::endl;
                        showLine(in, m_materials[j].line_pos);
                        note(m_materials[i].line_number) << "first instance" << std::endl;
                        showLine(in, m_materials[i].line_pos);
                    }
                }
            }
        }
    }
}

void AC3D::checkUnusedMaterial(std::istream &in)
{
    if (!m_unused_material)
        return;

    if (!m_materials.empty())
    {
        for (const auto &material : m_materials)
        {
            if (!material.used)
            {
                warningWithCount(m_unused_material_count, material.line_number) << "unused material" << std::endl;
                showLine(in, material.line_pos);
            }
        }
    }
}

void AC3D::addConstPoly(std::vector<ConstPoly> &polys, const Object &object, const Matrix &matrix)
{
    if (object.type.type == "poly")
    {
        Matrix newMatrix = matrix;
        newMatrix.multiply(object.matrix);
        polys.emplace_back(&object, newMatrix);
    }
    else if (object.type.type == "group" || object.type.type == "world")
    {
        Matrix newMatrix = matrix;
        newMatrix.multiply(object.matrix);
        for (const auto &kid : object.kids)
        {
            addConstPoly(polys, kid, newMatrix);
        }
    }
}

void AC3D::checkOverlapping2SidedSurface(std::istream &in, const ConstPoly &object1, const ConstPoly &object2)
{
    for (const auto &surface1 : object1.object->surfaces)
    {
        for (const auto &surface2 : object2.object->surfaces)
        {
            if (surface1.isDoubleSided() || surface2.isDoubleSided())
            {
                if ((surface1.isPolygon() || surface1.isTriangleStrip()) &&
                    (surface2.isPolygon() || surface2.isTriangleStrip()))
                {
                    if (surface1.isPolygon() && surface1.refs.size() >= 3 &&
                        surface2.isPolygon() && surface2.refs.size() >= 3)
                    {
                        for (size_t i = 1; i < (surface1.refs.size() - 1); i++)
                        {
                            std::array<Point3, 3> triangle1{ object1.object->vertices[surface1.refs[0].index].vertex,
                                                             object1.object->vertices[surface1.refs[i].index].vertex,
                                                             object1.object->vertices[surface1.refs[i + 1].index].vertex };

                            if (degenerate(triangle1))
                                continue;

                            for (auto &triangle : triangle1)
                                object1.matrix.transformPoint(triangle);

                            for (size_t j = 1; j < (surface2.refs.size() - 1); j++)
                            {
                                std::array<Point3, 3> triangle2{ object2.object->vertices[surface2.refs[0].index].vertex,
                                                                 object2.object->vertices[surface2.refs[j].index].vertex,
                                                                 object2.object->vertices[surface2.refs[j + 1].index].vertex };

                                if (degenerate(triangle2))
                                    continue;

                                for (auto &triangle : triangle2)
                                    object2.matrix.transformPoint(triangle);

                                if (trianglesOverlap(triangle1, triangle2))
                                {
                                    warningWithCount(m_overlapping_2_sided_surface_count, surface2.line_number) <<
                                        "overlapping 2 sided surface (object: " <<
                                        object2.object->getName() << " texture: " << object2.object->getTexture() <<
                                        " sides: " << (surface2.isDoubleSided() ? "2)" : "1)") << std::endl;
                                    showLine(in, surface2.line_pos);
                                    note(surface2.refs[0].line_number) << "ref" << std::endl;
                                    showLine(in, surface2.refs[0].line_pos);
                                    note(surface2.refs[j].line_number) << "ref" << std::endl;
                                    showLine(in, surface2.refs[j].line_pos);
                                    note(surface2.refs[j + 1].line_number) << "ref" << std::endl;
                                    showLine(in, surface2.refs[j + 1].line_pos);

                                    note(surface1.line_number) << "first instance (object: " <<
                                        object1.object->getName() << " texture: " << object1.object->getTexture() <<
                                        " sides: " << (surface1.isDoubleSided() ? "2)" : "1)") << std::endl;
                                    showLine(in, surface1.line_pos);
                                    note(surface1.refs[0].line_number) << "ref" << std::endl;
                                    showLine(in, surface1.refs[0].line_pos);
                                    note(surface1.refs[i].line_number) << "ref" << std::endl;
                                    showLine(in, surface1.refs[j].line_pos);
                                    note(surface1.refs[i + 1].line_number) << "ref" << std::endl;
                                    showLine(in, surface1.refs[i + 1].line_pos);
                                }
                            }
                        }
                    }
                    else if (surface1.isTriangleStrip() && surface2.isTriangleStrip())
                    {
                        for (size_t i = 2; i < surface1.refs.size(); i++)
                        {
                            std::array<Point3, 3> triangle1;
                            std::array<size_t, 3> index1;

                            if ((i & 1u) == 0)
                            {
                                index1 = { i - 2, i - 1, i };
                                triangle1 = { object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }
                            else // reverse winding to match drawing order
                            {
                                index1 = { i - 1, i - 2, i };
                                triangle1 = { object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }

                            if (!degenerate(triangle1))
                            {
                                for (auto &triangle : triangle1)
                                    object1.matrix.transformPoint(triangle);

                                for (size_t j = 2; j < surface2.refs.size(); j++)
                                {
                                    std::array<Point3, 3> triangle2;
                                    std::array<size_t, 3> index2;

                                    if ((i & 1u) == 0)
                                    {
                                        index2 = { j - 2, j - 1, j };
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }
                                    else // reverse winding to match drawing order
                                    {
                                        index2 = { j - 1, j - 2, j };
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }

                                    if (!degenerate(triangle2))
                                    {
                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            warningWithCount(m_overlapping_2_sided_surface_count, surface2.line_number) <<
                                                "overlapping 2 sided surface (object: " <<
                                                object2.object->getName() << " texture: " << object2.object->getTexture() <<
                                                " sides: " << (surface2.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface2.line_pos);
                                            note(surface2.refs[index2[0]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[0]].line_pos);
                                            note(surface2.refs[index2[1]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[1]].line_pos);
                                            note(surface2.refs[index2[2]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[2]].line_pos);

                                            note(surface1.line_number) << "first instance (object: " <<
                                                object1.object->getName() << " texture: " << object1.object->getTexture() <<
                                                " sides: " << (surface1.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface1.line_pos);
                                            note(surface1.refs[index1[0]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[0]].line_pos);
                                            note(surface1.refs[index1[1]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[1]].line_pos);
                                            note(surface1.refs[index1[2]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[2]].line_pos);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (surface1.isPolygon() && surface2.isTriangleStrip())
                    {
                        if (surface1.refs.size() >= 3)
                        {
                            for (size_t i = 1; i < (surface1.refs.size() - 1); i++)
                            {
                                std::array<Point3, 3> triangle1{ object1.object->vertices[surface1.refs[0].index].vertex,
                                                                 object1.object->vertices[surface1.refs[i].index].vertex,
                                                                 object1.object->vertices[surface1.refs[i + 1].index].vertex };

                                if (degenerate(triangle1))
                                    continue;

                                for (auto &triangle : triangle1)
                                    object1.matrix.transformPoint(triangle);

                                for (size_t j = 2; j < surface2.refs.size(); j++)
                                {
                                    std::array<Point3, 3> triangle2;
                                    std::array<size_t, 3> index2;

                                    if ((i & 1u) == 0)
                                    {
                                        index2 = { j - 2, j - 1, j };
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }
                                    else // reverse winding to match drawing order
                                    {
                                        index2 = { j - 1, j - 2, j };
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }

                                    if (!degenerate(triangle2))
                                    {
                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            warningWithCount(m_overlapping_2_sided_surface_count, surface2.line_number) <<
                                                "overlapping 2 sided surface (object: " <<
                                                object2.object->getName() << " texture: " << object2.object->getTexture() <<
                                                " sides: " << (surface2.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface2.line_pos);
                                            note(surface2.refs[index2[0]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[0]].line_pos);
                                            note(surface2.refs[index2[1]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[1]].line_pos);
                                            note(surface2.refs[index2[2]].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[index2[2]].line_pos);

                                            note(surface1.line_number) << "first instance (object: " <<
                                                object1.object->getName() << " texture: " << object1.object->getTexture() <<
                                                " sides: " << (surface1.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface1.line_pos);
                                            note(surface1.refs[0].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[0].line_pos);
                                            note(surface1.refs[i].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[j].line_pos);
                                            note(surface1.refs[i + 1].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[i + 1].line_pos);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (surface1.isTriangleStrip() && surface2.isPolygon())
                    {
                        for (size_t i = 2; i < surface1.refs.size(); i++)
                        {
                            std::array<Point3, 3> triangle1;
                            std::array<size_t, 3> index1;

                            if ((i & 1u) == 0)
                            {
                                index1 = { i - 2, i - 1, i };
                                triangle1 = { object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }
                            else // reverse winding to match drawing order
                            {
                                index1 = { i - 1, i - 2, i };
                                triangle1 = { object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }

                            if (!degenerate(triangle1))
                            {
                                for (auto &triangle : triangle1)
                                    object1.matrix.transformPoint(triangle);

                                if (surface2.refs.size() >= 3)
                                {
                                    for (size_t j = 1; j < (surface2.refs.size() - 1); j++)
                                    {
                                        std::array<Point3, 3> triangle2{ object2.object->vertices[surface2.refs[0].index].vertex,
                                                                         object2.object->vertices[surface2.refs[j].index].vertex,
                                                                         object2.object->vertices[surface2.refs[j + 1].index].vertex };

                                        if (degenerate(triangle2))
                                            continue;

                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            warningWithCount(m_overlapping_2_sided_surface_count, surface2.line_number) <<
                                                "overlapping 2 sided surface (object: " <<
                                                object2.object->getName() << " texture: " << object2.object->getTexture() <<
                                                " sides: " << (surface2.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface2.line_pos);
                                            note(surface2.refs[0].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[0].line_pos);
                                            note(surface2.refs[j].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[j].line_pos);
                                            note(surface2.refs[j + 1].line_number) << "ref" << std::endl;
                                            showLine(in, surface2.refs[j + 1].line_pos);

                                            note(surface1.line_number) << "first instance (object: " <<
                                                object1.object->getName() << " texture: " << object1.object->getTexture() <<
                                                " sides: " << (surface1.isDoubleSided() ? "2)" : "1)") << std::endl;
                                            showLine(in, surface1.line_pos);
                                            note(surface1.refs[index1[0]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[0]].line_pos);
                                            note(surface1.refs[index1[1]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[1]].line_pos);
                                            note(surface1.refs[index1[2]].line_number) << "ref" << std::endl;
                                            showLine(in, surface1.refs[index1[2]].line_pos);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

void AC3D::checkOverlapping2SidedSurface(std::istream &in)
{
    if (!m_overlapping_2_sided_surface)
        return;

    std::chrono::system_clock::time_point start;

    if (m_show_times)
    {
        std::cout << "checkOverlapping2SidedSurface starting" << std::endl;
        start = std::chrono::system_clock::now();
    }

    std::vector<ConstPoly> polys;
    const Matrix matrix;

    for (const auto &world : m_objects)
        addConstPoly(polys, world, matrix);

    if (polys.empty())
        return;

    const int size1 = static_cast<int>(polys.size() - 1);
    const int size2 = static_cast<int>(polys.size());
    for (int i = 0; i < size1; ++i)
    {
        for (int j = i + 1; j < size2; ++j)
            checkOverlapping2SidedSurface(in, polys[i], polys[j]);
    }

    if (m_show_times)
    {
        const std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
        std::cout << "checkOverlapping2SidedSurface done: duration: " << getDuration(start, end) << std::endl;
    }
}

bool AC3D::Triangle::sameTriangle(const Object &object, const Surface &surface, Difference difference) const
{
    if (!surface.isTriangle())
        return false;

    if (difference == Difference::None)
    {
        return (vertices[0].vertex == object.vertices[surface.refs[0].index].vertex) &&
               (vertices[1].vertex == object.vertices[surface.refs[1].index].vertex) &&
               (vertices[2].vertex == object.vertices[surface.refs[2].index].vertex);
    }

    if (difference == Difference::Order)
    {
        for (size_t i = 0; i < 3; i++)
        {
            for (size_t j = 0; j < 3; j++)
            {
                if (vertices[i].vertex == object.vertices[surface.refs[j].index].vertex)
                {
                    bool same = true;
                    for (size_t k = 1; k < 3; k++)
                    {
                        if (vertices[(i + k) % 3].vertex != vertices[surface.refs[(j + k) % 3].index].vertex)
                        {
                            same = false;
                            break;
                        }
                    }
                    if (same)
                        return true;
                }
            }
        }
    }

    if (difference == Difference::Winding)
    {
        for (size_t i = 0; i < 3; i++)
        {
            for (size_t j = 0; j < 3; j++)
            {
                if (vertices[i].vertex == object.vertices[surface.refs[j].index].vertex)
                {
                    bool same = true;
                    for (size_t k = 1; k < 3; k++)
                    {
                        if (vertices[(i + k) % 3].vertex != vertices[surface.refs[(j + 3 - k) % 3].index].vertex)
                        {
                            same = false;
                            break;
                        }
                    }
                    if (same)
                        return true;
                }
            }
        }
    }

    return false;
}

void AC3D::checkDuplicateTriangles(std::istream &in, const Object &object)
{
    if (!m_duplicate_triangles)
        return;

    if (m_is_ac)
        return;

    if (object.surfaces.empty())
        return;

    for (size_t i = 0, endi = object.surfaces.size() - 1; i < endi; ++i)
    {
        const Surface &surface1 = object.surfaces[i];

        for (size_t j = i + 1; j < object.surfaces.size(); ++j)
        {
            const Surface &surface2 = object.surfaces[j];

            if (surface1.isTriangleStrip())
            {
                for (size_t k = 0; k < surface1.triangleStrip.size(); k++)
                {
                    const Triangle &triangle1 = surface1.triangleStrip[k];

                    if (surface2.isTriangleStrip())
                    {
                        for (size_t l = 0; l < surface2.triangleStrip.size(); l++)
                        {
                            const Triangle &triangle2 = surface2.triangleStrip[l];

                            if (triangle1.sameTriangle(triangle2, Difference::None))
                            {
                                warningWithCount(m_duplicate_triangles_count, surface2.line_number) << "duplicate triangle" << std::endl;
                                showLine(in, surface2.line_pos);
                                note(triangle2.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle2.refs[2].line_pos);
                                note(surface1.line_number) << "first instance" << std::endl;
                                showLine(in, surface1.line_pos);
                                note(triangle1.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle1.refs[2].line_pos);
                            }
                            else if (triangle1.sameTriangle(triangle2, Difference::Order))
                            {
                                warning(surface2.line_number) << "duplicate triangle with different vertex order" << std::endl;
                                showLine(in, surface2.line_pos);
                                note(triangle2.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle2.refs[2].line_pos);
                                note(surface1.line_number) << "first instance" << std::endl;
                                showLine(in, surface1.line_pos);
                                note(triangle1.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle1.refs[2].line_pos);
                            }
                            else if (triangle1.sameTriangle(triangle2, Difference::Winding))
                            {
                                warning(surface2.line_number) << "duplicate triangle with different winding" << std::endl;
                                showLine(in, surface2.line_pos);
                                note(triangle2.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle2.refs[2].line_pos);
                                note(surface1.line_number) << "first instance" << std::endl;
                                showLine(in, surface1.line_pos);
                                note(triangle1.refs[2].line_number) << "ref" << std::endl;
                                showLine(in, triangle1.refs[2].line_pos);
                            }
                        }
                    }
                    else if (surface2.isTriangle())
                    {
                        if (triangle1.sameTriangle(object, surface2, Difference::None))
                        {
                            warning(surface2.line_number) << "duplicate triangle" << std::endl;
                            showLine(in, surface2.line_pos);
                            note(surface1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, surface1.refs[2].line_pos);
                            note(surface1.line_number) << "first instance" << std::endl;
                            showLine(in, surface1.line_pos);
                            note(triangle1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, triangle1.refs[2].line_pos);
                        }
                        else if (triangle1.sameTriangle(object, surface2, Difference::Order))
                        {
                            warning(surface2.line_number) << "duplicate triangle with different vertex order" << std::endl;
                            showLine(in, surface2.line_pos);
                            note(surface1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, surface1.refs[2].line_pos);
                            note(surface1.line_number) << "first instance" << std::endl;
                            showLine(in, surface1.line_pos);
                            note(triangle1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, triangle1.refs[2].line_pos);
                        }
                        else if (triangle1.sameTriangle(object, surface2, Difference::Winding))
                        {
                            warning(surface2.line_number) << "duplicate triangle with different winding" << std::endl;
                            showLine(in, surface2.line_pos);
                            note(surface1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, surface1.refs[2].line_pos);
                            note(surface1.line_number) << "first instance" << std::endl;
                            showLine(in, surface1.line_pos);
                            note(triangle1.refs[2].line_number) << "ref" << std::endl;
                            showLine(in, triangle1.refs[2].line_pos);
                        }
                    }
                }
            }
            else if (surface2.isTriangleStrip())
            {
                for (size_t k = 0; k < surface2.triangleStrip.size(); k++)
                {
                    const Triangle &triangle2 = surface2.triangleStrip[k];

                    if (triangle2.sameTriangle(object, surface1, Difference::None))
                    {
                        warning(surface2.line_number) << "duplicate triangle" << std::endl;
                        showLine(in, surface2.line_pos);
                        note(triangle2.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, triangle2.refs[2].line_pos);
                        note(surface1.line_number) << "first instance" << std::endl;
                        showLine(in, surface1.line_pos);
                        note(surface1.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, surface1.refs[2].line_pos);
                    }
                    else if (triangle2.sameTriangle(object, surface1, Difference::Order))
                    {
                        warning(surface2.line_number) << "duplicate triangle with different vertex order" << std::endl;
                        showLine(in, surface2.line_pos);
                        note(triangle2.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, triangle2.refs[2].line_pos);
                        note(surface1.line_number) << "first instance" << std::endl;
                        showLine(in, surface1.line_pos);
                        note(surface1.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, surface1.refs[2].line_pos);
                    }
                    else if (triangle2.sameTriangle(object, surface1, Difference::Winding))
                    {
                        warning(surface2.line_number) << "duplicate triangle with different winding" << std::endl;
                        showLine(in, surface2.line_pos);
                        note(triangle2.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, triangle2.refs[2].line_pos);
                        note(surface1.line_number) << "first instance" << std::endl;
                        showLine(in,surface1.line_pos);
                        note(surface1.refs[2].line_number) << "ref" << std::endl;
                        showLine(in, surface1.refs[2].line_pos);
                    }
                }
            }
        }
    }
}

void AC3D::checkMissingSurfaces(std::istream &in, const Object &object)
{
    if (!m_missing_surfaces)
        return;

    if (object.type.type != "poly")
        return;

    if (object.surfaces.empty())
    {
        warningWithCount(m_missing_surfaces_count, object.line_number) << "missing surfaces" << std::endl;
        showLine(in, object.line_pos);
    }
}

void AC3D::checkDuplicateSurfaces(std::istream &in, const Object &object)
{
    if (object.surfaces.empty())
        return;

    for (size_t i = 0, endi = object.surfaces.size(); i < endi; ++i)
    {
        for (size_t j = i + 1; j < object.surfaces.size(); ++j)
        {
            if (m_duplicate_surfaces && object.sameSurface(i, j, Difference::None))
            {
                warningWithCount(m_duplicate_surfaces_count, object.surfaces[j].line_number) << "duplicate surfaces" << std::endl;
                showLine(in, object.surfaces[j].line_pos);
                note(object.surfaces[i].line_number) << "first instance" << std::endl;
                showLine(in, object.surfaces[i].line_pos);
                continue;
            }

            // skip when triangle strip
            if (object.surfaces[i].isTriangleStrip() || object.surfaces[j].isTriangleStrip())
                continue;

            if (m_duplicate_surfaces_order && object.sameSurface(i, j, Difference::Order))
            {
                warningWithCount(m_duplicate_surfaces_order_count, object.surfaces[j].line_number) << "duplicate surfaces with different vertex order" << std::endl;
                showLine(in, object.surfaces[j].line_pos);
                note(object.surfaces[i].line_number) << "first instance" << std::endl;
                showLine(in, object.surfaces[i].line_pos);
                continue;
            }

            if (m_duplicate_surfaces_winding && object.sameSurface(i, j, Difference::Winding))
            {
                warningWithCount(m_duplicate_surfaces_winding_count, object.surfaces[j].line_number) << "duplicate surfaces with different winding" << std::endl;
                showLine(in, object.surfaces[j].line_pos);
                note(object.surfaces[i].line_number) << "first instance" << std::endl;
                showLine(in, object.surfaces[i].line_pos);
            }
        }
    }
}

void AC3D::checkUnusedVertex(std::istream &in, const Object &object)
{
    if (!m_unused_vertex)
        return;

    for (const auto &vertex : object.vertices)
    {
        if (!vertex.used)
        {
            warningWithCount(m_unused_vertex_count, vertex.line_number) << "unused vertex" << std::endl;
            showLine(in, vertex.line_pos);
        }
    }
}

void AC3D::checkDifferentSURF(std::istream& in, const Object& object)
{
    if (!m_different_surf)
        return;

    if (object.surfaces.empty())
        return;

    const unsigned int flags = object.surfaces[0].flags;

    for (size_t i = 1; i < object.surfaces.size(); ++i)
    {
        if (object.surfaces[i].flags != flags)
        {
            warningWithCount(m_different_surf_count, object.surfaces[i].line_number) << "different SURF (object: " << object.getName() << ")" << std::endl;
            showLine(in, object.surfaces[i].line_pos);
            note(object.surfaces[0].line_number) << "SURF" << std::endl;
            showLine(in, object.surfaces[0].line_pos);
        }
    }
}

void AC3D::checkDifferentMat(std::istream& in, const Object& object)
{
    if (!m_different_mat)
        return;

    if (object.surfaces.empty())
        return;

    if (object.surfaces[0].mats.empty())
        return;

    const size_t mat = object.surfaces[0].mats[0].mat;

    for (size_t i = 1; i < object.surfaces.size(); ++i)
    {
        if (!object.surfaces[i].mats.empty() && object.surfaces[i].mats[0].mat != mat)
        {
            warningWithCount(m_different_mat_count, object.surfaces[i].mats[0].line_number) << "different mat" << std::endl;
            showLine(in, object.surfaces[i].mats[0].line_pos);
            note(object.surfaces[0].mats[0].line_number) << "mat" << std::endl;
            showLine(in, object.surfaces[0].mats[0].line_pos);
        }
    }
}

void AC3D::checkDifferentUV(std::istream &in, const Object &object)
{
    if (!m_different_uv)
        return;

    // only check texture coordinates when texture is present
    if (object.textures.empty() || object.textures[0].name == "empty_texture_no_mapping")
        return;

    using RefPtr = const Ref*;

    struct CmpRefPtr
    {
        bool operator()(const RefPtr &lhs, const RefPtr &rhs) const
        {
            return (lhs->line_number < rhs->line_number);
        }
    };

    using RefPtrSet = std::set<RefPtr, CmpRefPtr>;

    std::map<size_t, RefPtrSet> matches;

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        const Surface &surface1 = object.surfaces[i];

        for (size_t j = 0; j < object.surfaces.size(); ++j)
        {
            const Surface &surface2 = object.surfaces[j];

            for (size_t k = 0; k < surface1.refs.size(); ++k)
            {
                for (size_t l = 0; l < surface2.refs.size(); ++l)
                {
                    if (surface1.refs[k].index == surface2.refs[l].index &&
                        surface1.refs[k].coordinates != surface2.refs[l].coordinates)
                    {
                        const double angle = std::acos(surface1.normal.dot(surface2.normal)) * 180.0 / M_PI;
                        const double crease = object.creases.empty() ? 45.0 : object.creases[0].crease;

                        if (angle < crease)
                        {
                            auto item = matches.find(surface1.refs[k].index);
                            if (item != matches.end())
                            {
                                if (item->second.find(&surface2.refs[l]) == item->second.end())
                                    item->second.insert(&surface2.refs[l]);
                            }
                            else
                            {
                                const RefPtrSet refs = { &surface1.refs[k], &surface2.refs[l] };
                                matches.insert(std::make_pair(surface1.refs[k].index, refs));
                            }
                        }
                    }
                }
            }
        }
    }

    for (const auto &item : matches)
    {
        bool first = true;
        for (const auto &entry : item.second)
        {
            if (first)
            {
                warningWithCount(m_different_uv_count, entry->line_number) << "different uv" << std::endl;
                showLine(in, entry->line_pos);
                first = false;
            }
            else
            {
                note(entry->line_number) << "instance" << std::endl;
                showLine(in, entry->line_pos);
            }
        }
    }
}

void AC3D::checkGroupWithGeometry(std::istream& in, const Object& object)
{
    if (!m_group_with_geometry)
        return;

    if (object.type.type == "group" && !object.vertices.empty())
    {
        warningWithCount(m_group_with_geometry_count, object.type.line_number) << "group with geometry" << std::endl;
        showLine(in, object.type.line_pos, object.type.type_offset);
        note(object.numvert.line_number) << "geometry" << std::endl;
        showLine(in, object.numvert.line_pos);
    }
}

void AC3D::checkDuplicateSurfaceVertices(std::istream &in, const Object &object, Surface &surface)
{
    if (surface.refs.empty())
        return;

    for (size_t i = 0, endi = surface.refs.size() - 1; i < endi; ++i)
    {
        for (size_t j = i + 1; j < surface.refs.size(); ++j)
        {
            // skip invalid vertex
            if (surface.refs[i].index >= object.vertices.size() ||
                surface.refs[j].index >= object.vertices.size())
                continue;

            if (surface.refs[i].index == surface.refs[j].index ||
                object.vertices[surface.refs[i].index] == object.vertices[surface.refs[j].index])
            {
                // triangle strips and lines can have duplicates
                if (surface.isPolygon() || surface.isClosedLine())
                {
                    if (j == i + 1 || j == surface.refs.size() - 1)
                    {
                        surface.refs[j].duplicate = true;

                        if (m_duplicate_surface_vertices)
                        {
                            warningWithCount(m_duplicate_surface_vertices_count, surface.refs[j].line_number) << "duplicate surface vertices" << std::endl;
                            showLine(in, surface.refs[j].line_pos);
                            if (surface.refs[i].index != surface.refs[j].index)
                            {
                                note(object.vertices[surface.refs[j].index].line_number) << "vertex" << std::endl;
                                showLine(in, object.vertices[surface.refs[j].index].line_pos);
                            }
                            note(surface.refs[i].line_number) << "first instance" << std::endl;
                            showLine(in, surface.refs[i].line_pos);
                            if (surface.refs[i].index != surface.refs[j].index)
                            {
                                note(object.vertices[surface.refs[i].index].line_number) << "vertex" << std::endl;
                                showLine(in, object.vertices[surface.refs[i].index].line_pos);
                            }
                        }
                    }
                    else
                    {
                        if (m_multiple_polygon_surface)
                        {
                            warningWithCount(m_multiple_polygon_surface_count, surface.refs[j].line_number) << "multiple polygon surface" << std::endl;
                            showLine(in, surface.refs[j].line_pos);
                            if (surface.refs[i].index != surface.refs[j].index)
                            {
                                note(object.vertices[surface.refs[j].index].line_number) << "vertex" << std::endl;
                                showLine(in, object.vertices[surface.refs[j].index].line_pos);
                            }
                            note(surface.refs[i].line_number) << "first instance" << std::endl;
                            showLine(in, surface.refs[i].line_pos);
                            if (surface.refs[i].index != surface.refs[j].index)
                            {
                                note(object.vertices[surface.refs[i].index].line_number) << "vertex" << std::endl;
                                showLine(in, object.vertices[surface.refs[i].index].line_pos);
                            }
                        }
                    }
                }
            }
        }
    }
}

void AC3D::checkDuplicateVertices(std::istream &in, const Object &object)
{
    if (!m_duplicate_vertices)
        return;

    std::vector<bool> duplicates(object.vertices.size(), false);

    for (size_t i = 0; i < object.vertices.size(); i++)
    {
        if (duplicates[i])
            continue;

        for (size_t j = i + 1; j < object.vertices.size(); j++)
        {
            if (object.vertices[i] == object.vertices[j])
            {
                duplicates[j] = true;

                warningWithCount(m_duplicate_vertices_count, object.vertices[j].line_number) << "duplicate verticies" << std::endl;
                showLine(in, object.vertices[j].line_pos);
                note(object.vertices[i].line_number) << "first instance" << std::endl;
                showLine(in, object.vertices[i].line_pos);
            }
        }
    }
}

bool AC3D::collinear(const Point3 &p1, const Point3 &p2, const Point3 &p3)
{
    constexpr double epsilon = static_cast<double>(std::numeric_limits<float>::epsilon());
    const Point3 v = Point3{p2 - p1}.cross(p3 - p1);
    return std::fabs(v.x()) < epsilon &&
           std::fabs(v.y()) < epsilon &&
           std::fabs(v.z()) < epsilon;
}

void AC3D::checkCollinearSurfaceVertices(std::istream &in, const Object &object, Surface &surface)
{
    const size_t size = surface.refs.size();
    size_t found = 0;

    // must be a polygon with at least 3 sides
    if (!surface.isPolygon())
        return;

    if (size < 3)
    {
        if (m_invalid_ref_count)
        {
            warningWithCount(m_invalid_ref_count_count, surface.refs.line_number) << "invalid ref count" << std::endl;
            showLine(in, surface.refs.line_pos);
        }
        return;
    }

    const size_t vertices = object.vertices.size();
    if (surface.refs[0].index >= vertices || surface.refs[1].index >= vertices)
        return;

    for (size_t i = 2; i < size + 2; ++i)
    {
        if (i < size && surface.refs[i].index >= vertices)
            return;

        const Point3 &v0 = object.vertices[surface.refs[i - 2].index].vertex;
        const Point3 &v1 = object.vertices[surface.refs[(i - 1) % size].index].vertex;
        const Point3 &v2 = object.vertices[surface.refs[i % size].index].vertex;

        if (v0 != v1 && v1 != v2 && (v0 == v2 || collinear(v0, v1, v2)))
        {
            // don't show all combinations when all vertices are collinear
            if (found < (size - 2) && m_collinear_surface_vertices)
            {
                warningWithCount(m_collinear_surface_vertices_count, surface.refs[i % size].line_number) << "collinear verticies" << std::endl;
                showLine(in, surface.refs[i % size].line_pos);

                note(object.vertices[surface.refs[i - 2].index].line_number) << "first vertex" << std::endl;
                showLine(in, object.vertices[surface.refs[i - 2].index].line_pos);
                note(object.vertices[surface.refs[(i - 1) % size].index].line_number) << "second vertex" << std::endl;
                showLine(in, object.vertices[surface.refs[(i - 1) % size].index].line_pos);
                note(object.vertices[surface.refs[i % size].index].line_number) << "third vertex" << std::endl;
                showLine(in, object.vertices[surface.refs[i % size].index].line_pos);
            }

            found++;
            surface.refs[(i - 1) % size].collinear = true;
        }
    }
}

void AC3D::checkSurfaceCoplanar(std::istream &in, const Object &object, Surface &surface)
{
    // only check polygon
    if (!surface.isPolygon())
        return;

    if (surface.refs.size() > 2)
    {
        size_t next = 0;
        Point3 p0;
        Point3 p1;
        Point3 p2;

        if (!object.getSurfaceVertex(surface, next++, p0))
            return;

        if (!object.getSurfaceVertex(surface, next++, p1))
            return;

        // find the next unique vertex
        while (p0 == p1)
        {
            if (!object.getSurfaceVertex(surface, next++, p1))
                return;
        }

        if (!object.getSurfaceVertex(surface, next++, p2))
            return;

        // find the next unique vertex
        while (p1 == p2 || collinear(p0, p1, p2))
        {
            if (!object.getSurfaceVertex(surface, next++, p2))
                return;
        }

        const Point3 v = Point3{p1 - p0}.cross(p2 - p0);
        surface.normal = v;

        surface.normal.normalize();

        // must have 4 or more vertices
        if (surface.refs.size() < 4)
            return;

        const double d = -v.x() * p1.x() - v.y() * p1.y() - v.z() * p1.z();

        for (size_t i = next; i < surface.refs.size(); ++i)
        {
            Point3 p;
            if (!object.getSurfaceVertex(surface, i, p))
                return;

            const double e = v.x() * p.x() + v.y() * p.y() + v.z() * p.z() + d;
            constexpr double epsilon = static_cast<double>(std::numeric_limits<float>::epsilon()) * 1000;
            if (std::fabs(e) > epsilon)
            {
                surface.coplanar = false;

                if (m_surface_not_coplanar)
                {
                    warningWithCount(m_surface_not_coplanar_count, surface.line_number) << "surface not coplanar" << std::endl;
                    showLine(in, surface.line_pos);
                }

                break;
            }
        }
    }
}

bool AC3D::ccw(const Point2 &p1, const Point2 &p2, const Point2 &p3)
{
    const double val = (p2.y() - p1.y()) * (p3.x() - p2.x()) -
                       (p2.x() - p1.x()) * (p3.y() - p2.y());

    return (val < 0.0);
}

void AC3D::checkSurfaceNoTexture(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_surface_no_texture)
        return;

    if (!(surface.isPolygon() || surface.isTriangleStrip()))
        return;

    bool hasCoordinates = false;
    for (const auto & ref : surface.refs)
    {
        if (!ref.coordinates.empty() && (ref.coordinates[0].x() != 0 || ref.coordinates[0].y() != 0.0))
        {
            hasCoordinates = true;
            break;
        }
    }

    if (hasCoordinates && object.textures.empty())
    {
        warningWithCount(m_surface_no_texture_count, surface.line_number) << "surface with texture coordinates but no texture" << std::endl;
        showLine(in, surface.line_pos);
    }
}

void AC3D::checkSurface2SidedOpaque(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_surface_2_sided_opaque)
        return;

    if (!(surface.isPolygon() || surface.isTriangleStrip()))
        return;

    if (!surface.isDoubleSided())
        return;

    if (!hasTransparentTexture(object))
    {
        warningWithCount(m_surface_2_sided_opaque_count, surface.line_number) << "2 sided surface with opaque texture (object: "
            << object.getName() << " texture: " << object.getTexture() << ")" << std::endl;
        showLine(in, surface.line_pos);
    }
}

void AC3D::checkSurfacePolygonType(std::istream &in, const Object &object, Surface &surface)
{
    // only check coplanar polygon
    if (!(surface.isPolygon() && surface.coplanar))
        return;

    // must have 3 or more vertices
    if (surface.refs.size() > 2)
    {
        size_t next = 0;
        Point2 p0;
        Point2 p1;
        Point2 p2;

        // project 3d coordinates onto 2d plane
        const PlaneType planeType = getPlaneType(surface.normal);

        if (!object.getSurfaceVertex(surface, next++, p0, planeType))
            return;

        if (!object.getSurfaceVertex(surface, next++, p1, planeType))
            return;

        // find the next unique non-collnear vertex
        while (p0 == p1 || surface.refs[next - 1].collinear)
        {
            if (!object.getSurfaceVertex(surface, next++, p1, planeType))
                return;
        }

        if (!object.getSurfaceVertex(surface, next++, p2, planeType))
            return;

        // find the next unique non-collnear vertex
        while (p1 == p2 || surface.refs[next - 1].collinear)
        {
            if (!object.getSurfaceVertex(surface, next++, p2, planeType))
                return;
        }

        // FIXME: this will be wrong when starting on a convex vertex
        const bool counterclockwise = ccw(p0, p1, p2);
        const size_t size = surface.refs.size();
        while (next < (size + 2))
        {
            p0 = p1;
            p1 = p2;
            if (!object.getSurfaceVertex(surface, next++ % size, p2, planeType))
                return;

            while (p1 == p2 || surface.refs[(next - 1) % size].collinear)
            {
                if (!object.getSurfaceVertex(surface, next++ % size, p2, planeType))
                    return;
            }

            if (ccw(p0, p1, p2) != counterclockwise && !surface.concave)
            {
                surface.concave = true;

                if (m_surface_not_convex)
                {
                    warningWithCount(m_surface_not_convex_count, surface.line_number) << "surface not convex" << std::endl;
                    showLine(in, surface.line_pos);
                    note(surface.refs[(next - 2) % size].line_number) << "concave vertex"  << std::endl;
                    showLine(in, surface.refs[(next - 2) % size].line_pos);
                }
            }
        }
    }
}

AC3D::Point3 AC3D::normalizedNormal(const Point3& p0, const Point3& p1, const Point3& p2)
{
    Point3  normal((p1 - p0).cross(p2 - p1));

    normal.normalize();

    return normal;
}

AC3D::Point3 AC3D::unnormalizedNormal(const Point3 &p0, const Point3 &p1, const Point3 &p2)
{
    return ((p1 - p0).cross(p2 - p1));
}

bool AC3D::degenerate(const std::array<Point3, 3> &vertices)
{
    return vertices[0].equals(vertices[1]) || vertices[0].equals(vertices[2]) || vertices[1].equals(vertices[2]);
}

bool AC3D::degenerate(const Point3 &p0, const Point3 &p1, const Point3 &p2)
{
    return p0 == p1 || p0 == p2 || p1 == p2;
}

bool AC3D::coplanar(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2)
{
    const Plane p1(vertices1);
    const Plane p2(vertices2);

    return p1.equals(p2);
}

bool AC3D::trianglesOverlap(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2)
{
    if (getSharedVertexCount(vertices1, vertices2) == 3)
        return true;

    if (!coplanar(vertices1, vertices2))
        return false;

    Point3 p1{ 0, 0, 0 }; // not used
    Point3 p2{ 0, 0, 0 }; // not used
    bool b = false; // not used

    return threeyd::moeller::TriangleIntersects<Point3>::triangle(
        vertices1[0], vertices1[1], vertices1[2],
        vertices2[0], vertices2[1], vertices2[2],
        p1, p2, b);
}

AC3D::PlaneType AC3D::getPlaneType(const Point3 &normal)
{
    // z largest so use xy plane
    if (std::fabs(normal.x()) < std::fabs(normal.z()) && std::fabs(normal.y()) < std::fabs(normal.z()))
        return PlaneType::xy;

    // y largest so use xz plane
    if (std::fabs(normal.x()) < std::fabs(normal.y()) && std::fabs(normal.z()) < std::fabs(normal.y()))
        return PlaneType::xz;

    // use yz plane
    return PlaneType::yz;
}

std::array<AC3D::Point2, 3> AC3D::convert2D(const std::array<Point3, 3> &vertices, PlaneType planeType)
{
    std::array<AC3D::Point2, 3> vertices2D = { 0, 0 };

    for (size_t i = 0; i < 3; i++)
    {
        switch (planeType)
        {
        case PlaneType::xy:
            vertices2D[i].x(vertices[i].x());
            vertices2D[i].y(vertices[i].y());
            break;
        case PlaneType::xz:
            vertices2D[i].x(vertices[i].x());
            vertices2D[i].y(vertices[i].z());
            break;
        case PlaneType::yz:
            vertices2D[i].x(vertices[i].y());
            vertices2D[i].y(vertices[i].z());
            break;
        }

    }
    return vertices2D;
}

size_t AC3D::getSharedVertexCount(const std::array<Point3, 3> &vertices1, const std::array<Point3, 3> &vertices2)
{
    size_t count = 0;

    for (const auto &vertex1 : vertices1)
    {
        for (const auto &vertex2 : vertices2)
        {
            if (vertex1.equals(vertex2))
                count++;
        }
    }

    return count;
}

// from http://geomalgorithms.com/a07-_distance.html
double AC3D::closest(const Point3 &p0, const Point3 &p1, const Point3 &p2, const Point3 &p3)
{
    const Point3  u = p1 - p0;
    const Point3  v = p3 - p2;
    const Point3  w = p0 - p2;
    const double  a = u.dot(u);         // always >= 0
    const double  b = u.dot(v);
    const double  c = v.dot(v);         // always >= 0
    const double  d = u.dot(w);
    const double  e = v.dot(w);
    const double  D = a*c - b*b;        // always >= 0
    double  sc, sN, sD = D;       // sc = sN / sD, default sD = D >= 0
    double  tc, tN, tD = D;       // tc = tN / tD, default tD = D >= 0
    constexpr double  SMALL_NUM = static_cast<double>(std::numeric_limits<double>::epsilon());

    // compute the line parameters of the two closest points
    if (D < SMALL_NUM) { // the lines are almost parallel
        sN = 0.0;        // force using point P0 on segment S1
        sD = 1.0;        // to prevent possible division by 0.0 later
        tN = e;
        tD = c;
    }
    else {               // get the closest points on the infinite lines
        sN = (b*e - c*d);
        tN = (a*e - b*d);
        if (sN < 0.0) {  // sc < 0 => the s=0 edge is visible
            sN = 0.0;
            tN = e;
            tD = c;
        }
        else if (sN > sD) {  // sc > 1  => the s=1 edge is visible
            sN = sD;
            tN = e + b;
            tD = c;
        }
    }

    if (tN < 0.0) {      // tc < 0 => the t=0 edge is visible
        tN = 0.0;
        // recompute sc for this edge
        if (-d < 0.0)
            sN = 0.0;
        else if (-d > a)
            sN = sD;
        else {
            sN = -d;
            sD = a;
        }
    }
    else if (tN > tD) {  // tc > 1  => the t=1 edge is visible
        tN = tD;
        // recompute sc for this edge
        if ((-d + b) < 0.0)
            sN = 0;
        else if ((-d + b) > a)
            sN = sD;
        else {
            sN = (-d +  b);
            sD = a;
        }
    }
    // finally do the division to get sc and tc
    sc = (std::fabs(sN) < SMALL_NUM ? 0.0 : sN / sD);
    tc = (std::fabs(tN) < SMALL_NUM ? 0.0 : tN / tD);

    // get the difference of the two closest points
    const Point3  dP = w + (u * sc) - (v * tc);  // =  S1(sc) - S2(tc)

    return dP.length();   // return the closest distance
}

void AC3D::checkSurfaceStripSize(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_surface_strip_size)
        return;

    if (m_is_ac)
        return;

    if (!surface.isTriangleStrip())
        return;

    if (surface.getTriangleStrip().size() < 2)
    {
        warningWithCount(m_surface_strip_size_count, surface.line_number) << "triangle strip with" << (surface.getTriangleStrip().empty() ? " no triangles" : " 1 triangle") << std::endl;
        showLine(in, surface.line_pos);
    }
}

bool AC3D::Triangle::sameTriangle(const Triangle &triangle, Difference difference) const
{
    if (difference == None)
        return vertices[0] == triangle.vertices[0] && vertices[1] == triangle.vertices[1] && vertices[2] == triangle.vertices[2];

    if (difference == Order)
        return (vertices[0] == triangle.vertices[1] && vertices[1] == triangle.vertices[2] && vertices[2] == triangle.vertices[0]) ||
               (vertices[0] == triangle.vertices[2] && vertices[1] == triangle.vertices[0] && vertices[2] == triangle.vertices[1]);

    if (difference == Winding)
        return (vertices[0] == triangle.vertices[2] && vertices[1] == triangle.vertices[1] && vertices[2] == triangle.vertices[0]) ||
               (vertices[0] == triangle.vertices[1] && vertices[1] == triangle.vertices[0] && vertices[2] == triangle.vertices[2]) ||
               (vertices[0] == triangle.vertices[0] && vertices[1] == triangle.vertices[2] && vertices[2] == triangle.vertices[1]);

    return false;
}

void AC3D::checkSurfaceStripDuplicateTriangles(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_surface_strip_duplicate_triangles)
        return;

    if (m_is_ac)
        return;

    if (!surface.isTriangleStrip())
        return;

    for (size_t i = 0; i < surface.triangleStrip.size(); i++)
    {
        for (size_t j = i + 1; j < surface.triangleStrip.size(); j++)
        {
            if (surface.triangleStrip[i].sameTriangle(surface.triangleStrip[j], Difference::None))
            {
                warningWithCount(m_surface_strip_duplicate_triangles_count, surface.line_number) << "triangle strip with duplicate triangle" << std::endl;
                showLine(in, surface.line_pos);
                note(surface.triangleStrip[i].refs[2].line_number) << "first triangle" << std::endl;
                showLine(in, surface.triangleStrip[i].refs[2].line_pos);
                note(surface.triangleStrip[j].refs[2].line_number) << "duplicate triangle" << std::endl;
                showLine(in, surface.triangleStrip[j].refs[2].line_pos);
            }

            if (surface.triangleStrip[i].sameTriangle(surface.triangleStrip[j], Difference::Order))
            {
                warning(surface.line_number) << "triangle strip with duplicate triangle with different vertex order" << std::endl;
                showLine(in, surface.line_pos);
                note(surface.triangleStrip[i].refs[2].line_number) << "first triangle" << std::endl;
                showLine(in, surface.triangleStrip[i].refs[2].line_pos);
                note(surface.triangleStrip[j].refs[2].line_number) << "duplicate triangle" << std::endl;
                showLine(in, surface.triangleStrip[j].refs[2].line_pos);
            }

            if (surface.triangleStrip[i].sameTriangle(surface.triangleStrip[j], Difference::Winding))
            {
                warning(surface.line_number) << "triangle strip with duplicate triangle with different winding" << std::endl;
                showLine(in, surface.line_pos);
                note(surface.triangleStrip[i].refs[2].line_number) << "first triangle" << std::endl;
                showLine(in, surface.triangleStrip[i].refs[2].line_pos);
                note(surface.triangleStrip[j].refs[2].line_number) << "duplicate triangle" << std::endl;
                showLine(in, surface.triangleStrip[j].refs[2].line_pos);
            }
        }
    }
}

void AC3D::checkSurfaceStripDegenerate(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_surface_strip_degenerate)
        return;

    if (m_is_ac)
        return;

    if (!surface.isTriangleStrip())
        return;

    size_t count = 0;
    for (const auto & triangle : surface.getTriangleStrip())
    {
        if (triangle.degenerate)
            count++;
    }

    if (count > 0)
    {
        const double size = static_cast<double>(surface.getTriangleStrip().size());
        warningWithCount(m_surface_strip_degenerate_count, surface.line_number) << "triangle strip " << count << " out of " << size << " ("
            << ((count / size) * 100.0) << " percent) degenerate triangles" << std::endl;
        showLine(in, surface.line_pos);
    }
}

void AC3D::checkSurfaceStripHole(std::istream& in, const Object& object, const Surface& surface)
{
    if (!m_surface_strip_hole)
        return;

    if (m_is_ac)
        return;

    if (!surface.isTriangleStrip() || surface.isDoubleSided())
        return;

    const std::vector<Triangle> &triangleStrip = surface.getTriangleStrip();

    if (triangleStrip.size() < 2)
        return;

    const auto &triangles = surface.getTriangleStrip();
    bool hasOldNormal = false;
    Point3 oldNormal{ 0.0, 0.0, 0.0 };
    size_t oldTriangleIndex = 0;
    std::vector<size_t> holes;

    for (size_t i = 0; i < triangles.size(); i++)
    {
        if (triangles[i].degenerate)
            continue;

        const Point3 &newNormal = triangles[i].normal;

        if (hasOldNormal)
        {
            // find plane perpendicular to triangle running through shared edge
            const Plane perpendicular(triangles[i].vertices[0].vertex,
                                      triangles[i].vertices[1].vertex,
                                      triangles[i].vertices[0].vertex + triangles[oldTriangleIndex].normal);

            // find out which side of plane third vertex is in
            const bool above = perpendicular.isAbovePlane(triangles[i].vertices[2].vertex);

            // check normals for different winding
            const double dot = oldNormal.dot(newNormal);
            if (above)
            {
                if (dot > 0)
                    holes.push_back(i);
            }
            else
            {
                if (dot < 0)
                    holes.push_back(i);
            }
        }

        oldNormal = newNormal;
        oldTriangleIndex = i;
        hasOldNormal = true;
    }

    if (!holes.empty())
    {
        const std::string s(holes.size() != 1 ? "s" : "");

        warningWithCount(m_surface_strip_hole_count, surface.line_number) << "triangle strip with " << holes.size() << " possible hole"
            << s << " (reversed triangle" << s << ")" << std::endl;
        showLine(in, surface.line_pos);
        for (auto hole : holes)
        {
            note(triangles[hole].refs[2].line_number) << "ref" << std::endl;
            showLine(in, triangles[hole].refs[2].line_pos);
        }
    }
}

void AC3D::checkSurfaceSelfIntersecting(std::istream &in, const Object &object, const Surface &surface)
{
    // only check coplanar polygon
    if (!(surface.isPolygon() && surface.coplanar))
        return;

    if (surface.refs.size() > 3)
    {
        const size_t size = surface.refs.size();
        const size_t count = size - 2;

        for (size_t j = 0; j < count; j++)
        {
            size_t next = j;
            size_t end = j + size - 1;

            Point3 p0;
            Point3 p1;
            Point3 p2;
            Point3 p3;
            Point3 p4;

            // get first vertex of first line segment
            if (!object.getSurfaceVertex(surface, next++, p0))
                return;

            // find the second vertex of the first line segment
            if (!object.getSurfaceVertex(surface, next++, p1))
                return;

            // find the vertex after the first line segment
            if (!object.getSurfaceVertex(surface, next, p2))
                return;

            // skip duplicate and collinear vertices
            while (p0 == p1 || p1 == p2 || surface.refs[next - 1].collinear)
            {
                end--;
                next++;
                p1 = p2;
                if (!object.getSurfaceVertex(surface, next, p2))
                    return;
            }

            while (next < end)
            {
                // find the first vertex of the second line segment
                if (!object.getSurfaceVertex(surface, next++ % size, p2))
                    return;

                // find the second vertex of the second line segment
                if (!object.getSurfaceVertex(surface, next % size, p3))
                    return;

                // find the vertex after the second line segment
                if (!object.getSurfaceVertex(surface, (next + 1) % size, p4))
                    return;

                // skip duplicate and collinear vertices
                while (p2 == p3 || p3 == p4 || surface.refs[next % size].collinear)
                {
                    end--;
                    next++;
                    p3 = p4;
                    if (!object.getSurfaceVertex(surface, next % size, p4))
                        return;
                }

                if (next <= end)
                {
                    const double distance = closest(p0, p1, p2, p3);

                    if (distance < static_cast<double>(std::numeric_limits<double>::epsilon()))
                    {
                        if (m_surface_self_intersecting)
                        {
                            warningWithCount(m_surface_self_intersecting_count, surface.line_number) << "surface self intersecting" << std::endl;
                            showLine(in, surface.line_pos);
                        }
                        return;
                    }
                }
            }
        }
    }
}

bool AC3D::write(const std::string &file, int version)
{
    const std::string extension = std::filesystem::path(file).extension().string();
    bool is_ac;

    if (extension == ".ac")
        is_ac = true;
    else if (extension == ".acc")
        is_ac = false;
    else
    {
        std::cerr << "Unknown file extension: \"" << extension << "\"" << std::endl;
        return false;
    }

    if (m_is_ac && !is_ac) // convert .ac to .acc
        convertObjectsToAcc(m_objects);
    else if (!m_is_ac && is_ac) // convert .acc to .ac
        convertObjectsToAc(m_objects);

    std::ofstream of(file, std::ofstream::binary);

    if (!of)
        return false;

    if (version == 12)
    {
        m_header.version = "AC3Dc";

        for (auto& material : m_materials)
            material.version12 = true;
    }
    else if (version == 11)
    {
        m_header.version = "AC3Db";

        for (auto& material : m_materials)
            material.version12 = false;
    }

    writeHeader(of, m_header);

    for (const auto &material : m_materials)
        writeMaterial(of, material);

    for (const auto &object : m_objects)
        writeObject(of, object);

    return true;
}

bool AC3D::sameMaterial(const Material &material1, const Material &material2)
{
    return material1.name == material2.name && sameMaterialParameters(material1, material2);
}

bool AC3D::sameMaterialParameters(const Material &material1, const Material &material2)
{
    if (material1.rgb == material2.rgb &&
        material1.amb == material2.amb &&
        material1.emis == material2.emis &&
        material1.spec == material2.spec &&
        material1.shi == material2.shi &&
        material1.trans == material2.trans)
    {
        if (material1.data.size() == material2.data.size())
        {
            for (size_t i = 0; i < material1.data.size(); ++i)
            {
                if (material1.data[i].data != material2.data[i].data)
                    return false;
            }
            return true;
        }
    }

    return false;
}

bool AC3D::setMaterialUsed(size_t index)
{
    if (index < m_materials.size())
    {
        m_materials[index].used = true;
        return true;
    }

    return false;
}

bool AC3D::clean()
{
    std::chrono::system_clock::time_point start;

    if (m_show_times)
    {
        std::cout << "clean starting" << std::endl;
        start = std::chrono::system_clock::now();
    }

    bool cleaned = false;

    cleaned |= cleanMaterials();
    cleaned |= cleanVertices();
    cleaned |= cleanSurfaces();
    cleaned |= cleanVertices(); // cleanSurfaces may create unused vertices
    cleaned |= cleanObjects();

    if (m_show_times)
    {
        const std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
        std::cout << "clean done: duration: " << getDuration(start, end) << std::endl;
    }

    return cleaned;
}

bool AC3D::splitMultipleSURF()
{
    return splitMultipleSURF(m_objects);
}

bool AC3D::splitMultipleSURF(std::vector<Object> &kids)
{
    std::vector<Object> newKids;
    bool split = false;

    auto kid = kids.begin();
    while (kid != kids.end())
    {
        if (!kid->kids.empty())
            split |= splitMultipleSURF(kid->kids);

        if (kid->surfaces.empty())
        {
            ++kid;
            continue;
        }

        const unsigned int flags = kid->surfaces[0].flags;
        std::set<unsigned int> newFlags;

        for (size_t i = 1; i < kid->surfaces.size(); ++i)
        {
            if (kid->surfaces[i].flags != flags)
            {
                if (!newFlags.contains(kid->surfaces[i].flags))
                {
                    newFlags.insert(kid->surfaces[i].flags);
                    newKids.push_back(*kid);

                    if (!newKids.back().names.empty())
                        newKids.back().names[0].name += ("-split" + std::to_string(newKids.size()));

                    auto it = newKids.back().surfaces.begin();
                    while (it != newKids.back().surfaces.end())
                    {
                        // remove surfaces that don't match
                        if (it->flags != kid->surfaces[i].flags)
                            it = newKids.back().surfaces.erase(it);
                        else
                            ++it;
                    }
                }
            }
        }

        auto it = kid->surfaces.begin();
        while (it != kid->surfaces.end())
        {
            // remove surfaces that don't match
            if (it->flags != flags)
                it = kid->surfaces.erase(it);
            else
                ++it;
        }

        ++kid;
    }

    if (newKids.empty())
        return split;

    kids.insert(kids.end(), newKids.begin(), newKids.end());

    return true;
}

bool AC3D::splitMultipleMat()
{
    return splitMultipleMat(m_objects);
}

bool AC3D::splitMultipleMat(std::vector<Object> &kids)
{
    std::vector<Object> newKids;
    bool split = false;

    auto kid = kids.begin();
    while (kid != kids.end())
    {
        if (!kid->kids.empty())
            split |= splitMultipleMat(kid->kids);

        if (kid->surfaces.empty())
        {
            ++kid;
            continue;
        }

        if (kid->surfaces[0].mats.empty())
        {
            ++kid;
            continue;
        }

        const size_t mat = kid->surfaces[0].mats[0].mat;
        std::set<size_t> newMat;

        for (size_t i = 1; i < kid->surfaces.size(); ++i)
        {
            if (!kid->surfaces[i].mats.empty() && kid->surfaces[i].mats[0].mat != mat)
            {
                if (!newMat.contains(kid->surfaces[i].mats[0].mat))
                {
                    newMat.insert(kid->surfaces[i].mats[0].mat);
                    newKids.push_back(*kid);

                    if (!newKids.back().names.empty())
                        newKids.back().names[0].name += ("-split" + std::to_string(newKids.size()));

                    auto it = newKids.back().surfaces.begin();
                    while (it != newKids.back().surfaces.end())
                    {
                        // remove surfaces that don't match
                        if (it->mats[0].mat != kid->surfaces[i].mats[0].mat)
                            it = newKids.back().surfaces.erase(it);
                        else
                            ++it;
                    }
                }
            }
        }

        auto it = kid->surfaces.begin();
        while (it != kid->surfaces.end())
        {
            // remove surfaces that don't match
            if (it->mats[0].mat != mat)
                it = kid->surfaces.erase(it);
            else
                ++it;
        }

        ++kid;
    }

    if (newKids.empty())
        return split;

    kids.insert(kids.end(), newKids.begin(), newKids.end());

    return true;
}

bool AC3D::fixMultipleWorlds()
{
    // check for concatenated files
    if (!(m_objects.size() == 2 && m_objects[0].type.type == "world" && m_objects[1].type.type == "world"))
        return false;

    size_t materials = 0;
    size_t line_number = m_objects[1].line_number - 1;

    // check if concatenated file has materials
    for (auto it = m_materials.rbegin(); it != m_materials.rend(); ++it)
    {
        if (it->line_number == line_number)
        {
            materials++;
            line_number--;
        }
        else
            break;
    }

    if (materials != 0)
    {
        // TODO: change material index of concatenated file surfaces if necessary
        std::cerr << "Can't fix concatenated world with materials yet" << std::endl;
        return false;
    }

    m_objects[0].kids.insert(m_objects[0].kids.end(), m_objects[1].kids.begin(), m_objects[1].kids.end());

    m_objects.pop_back();

    return true;
}

bool AC3D::cleanMaterials()
{
    bool cleaned = false;

    for (auto &material : m_materials)
    {
        cleaned |= material.rgb.clip();
        cleaned |= material.amb.clip();
        cleaned |= material.emis.clip();
        cleaned |= material.spec.clip();

        const double shi = std::round(material.shi);

        if (shi != material.shi)
        {
            material.shi = shi;
            cleaned = true;
        }

        if (material.shi < 0.0)
        {
            material.shi = 0.0;
            cleaned = true;
        }
        else if (material.shi > 128.0)
        {
            material.shi = 128.0;
            cleaned = true;
        }

        if (material.trans < 0.0)
        {
            material.trans = 0.0;
            cleaned = true;
        }
        else if (material.trans > 1.0)
        {
            material.trans = 1.0;
            cleaned = true;
        }
    }

    std::vector<bool> duplicates(m_materials.size(), false);
    std::vector<size_t> newIndex;

    // assume no changes needed
    for (size_t i = 0; i < m_materials.size(); ++i)
        newIndex.push_back(i);

    for (size_t i = 0; i < m_materials.size(); ++i)
    {
        if (!duplicates[i])
        {
            for (size_t j = i + 1; j < m_materials.size(); ++j)
            {
                if (sameMaterialParameters(m_materials[i], m_materials[j]))
                {
                    // mark this instance as a duplicate
                    duplicates[j] = true;
                    // set new index to first instance index
                    newIndex[j] = i;
                    // mark first instance used if this instance used
                    if (m_materials[j].used)
                        m_materials[i].used = true;
                    // mark this instance not used
                    m_materials[j].used = false;
                }
            }
        }
    }

    for (size_t i = 0; i < m_materials.size(); ++i)
    {
        if (!m_materials[i].used)
        {
            // update index
            for (size_t j = i + 1; j < m_materials.size(); ++j)
            {
                if (newIndex[j] > 0)
                    newIndex[j]--;
            }
        }
    }

    for (size_t i = duplicates.size(); i > 0; --i)
    {
        const size_t index = i - 1;

        // remove unused materials
        if (!m_materials[index].used)
            m_materials.erase(m_materials.begin() + index);
    }

    cleaned |= cleanMaterials(m_objects, newIndex);

    return cleaned;
}

bool AC3D::cleanMaterials(std::vector<Object> &objects, const std::vector<size_t> &indexes)
{
    bool changed = false;

    for (auto &object : objects)
    {
        for (auto &surface : object.surfaces)
        {
            if (!surface.mats.empty() &&
                surface.mats.back().mat != indexes[surface.mats.back().mat])
            {
                changed = true;

                // update surface with new index
                surface.mats.back().mat = indexes[surface.mats.back().mat];
            }
        }

        changed |= cleanMaterials(object.kids, indexes);
    }

    return changed;
}

bool AC3D::cleanObjects()
{
    return cleanObjects(m_objects);
}

bool AC3D::cleanObjects(std::vector<Object> &objects)
{
    bool cleaned = false;
    auto it = objects.begin();

    while (it != objects.end())
    {
        if (it->type.type == "group" && !it->vertices.empty())
        {
            it->type.type = "poly";
            cleaned = true;
        }

        cleaned |= cleanObjects(it->kids);

        if (it->empty())
        {
            it = objects.erase(it);
            cleaned = true;
        }
        else if (it->type.type == "group" && it->kids.empty())
        {
            it = objects.erase(it);
            cleaned = true;
        }
        else
            ++it;
    }

    return cleaned;
}

bool AC3D::cleanVertices()
{
    std::chrono::system_clock::time_point start;

    if (m_show_times)
    {
        std::cout << "cleanVertices starting" << std::endl;
        start = std::chrono::system_clock::now();
    }

    const bool result = cleanVertices(m_objects);

    if (m_show_times)
    {
        const std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
        std::cout << "cleanVertices done: duration: " << getDuration(start, end) << std::endl;
    }

    return result;
}

bool AC3D::cleanVertices(std::vector<Object> &objects)
{
    bool cleaned = false;

    for (auto &object : objects)
    {
        cleaned |= cleanVertices(object);
        cleaned |= cleanVertices(object.kids);
    }

    return cleaned;
}

bool AC3D::cleanVertices(Object &object)
{
    if (object.vertices.empty())
        return false;

    bool can_clean = false;

    struct Info
    {
        bool used = false;      // used by surface
        bool duplicate = false; // duplicate vertex
        size_t new_index = 0;   // new index after unused and duplicates removed
    };

    std::vector<Info> info(object.vertices.size());

    // check for duplicate verticies
    for (size_t i = 0; i < object.vertices.size(); i++)
    {
        if (!info[i].duplicate)
            info[i].new_index = i;

        for (size_t j = i + 1; j < object.vertices.size(); j++)
        {
            if (!info[j].duplicate && object.vertices[i].vertex == object.vertices[j].vertex)
            {
                // normals must match when present
                if (!object.vertices[i].has_normal ||
                    object.vertices[i].normal == object.vertices[j].normal)
                {
                    info[j].duplicate = true;
                    info[j].new_index = i;
                    can_clean = true;
                }
            }
        }
    }

    // check for used verticies
    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        for (size_t j = 0; j < object.surfaces[i].refs.size(); j++)
        {
            const size_t index = object.surfaces[i].refs[j].index;

            if (index >= object.vertices.size())
                return false;

            if (info[index].duplicate)
            {
                const size_t new_index = info[index].new_index;

                object.surfaces[i].refs[j].index = new_index;

                // set first instance of vertex as used
                info[new_index].used = true;
            }
            else
            {
                // set vertex used
                info[index].used = true;
            }
        }
    }

    // check for unused vertices and update new_index for deleted vertex
    for (size_t i = 0; i < info.size(); ++i)
    {
        if (!info[i].used)
        {
            can_clean = true;

            for (size_t j = i + 1; j < info.size(); ++j)
            {
                if (info[j].used && info[j].new_index > 0)
                    info[j].new_index--;
            }
        }
    }

    // done if nothing to clean
    if (!can_clean)
        return false;

    // remove unused verticies
    for (size_t i = info.size(); i > 0; i--)
    {
        if (!info[i - 1].used)
            object.vertices.erase(object.vertices.begin() + i - 1);
    }

    // update surface indexes with new values
    for (auto &surface : object.surfaces)
    {
        for (auto &ref : surface.refs)
            ref.index = info[ref.index].new_index;
    }

    return true;
}

void AC3D::getObjects(std::vector<Object *> &polys, Object *object)
{
    if (object->type.type == "poly")
    {
        polys.push_back(object);
        return;
    }

    if (object->type.type == "group" || object->type.type == "world")
    {
        for (auto &kid : object->kids)
            getObjects(polys, &kid);
    }
}

bool AC3D::cleanSurfaces()
{
    std::vector<Object *> polys;

    // find all the polys
    for (auto &object : m_objects)
        getObjects(polys, &object);

    bool cleaned = false;

    std::chrono::system_clock::time_point start;

    if (m_show_times)
    {
        std::cout << "cleanSurfaces starting with " << m_threads << " thread" << (m_threads > 1 ? "s" : "") << std::endl;
        start = std::chrono::system_clock::now();
    }

    // clean them
    {
        const int size = static_cast<int>(polys.size());

        omp_set_dynamic(0);
        omp_set_num_threads(m_threads);

        #pragma omp parallel for reduction(|:cleaned)
        for (int i = 0; i < size; i++)
        {
            cleaned |= cleanSurfaces(*polys[i]);
        }
    }

    if (m_show_times)
    {
        const std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
        std::cout << "cleanSurfaces done: duration: " << getDuration(start, end) << std::endl;
    }

    return cleaned;
}

bool AC3D::cleanSurfaces(std::vector<Object> &objects)
{
    bool cleaned = false;

    for (auto &object : objects)
    {
        cleaned |= cleanSurfaces(object);
        cleaned |= cleanSurfaces(object.kids);
    }

    return cleaned;
}

bool AC3D::cleanSurfaces(Object &object)
{
    if (object.surfaces.empty())
        return false;

    bool cleaned = false;

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        Surface &surface = object.surfaces[i];
        auto it = surface.refs.begin();
        while (it != surface.refs.end())
        {
            if (it->duplicate)
            {
                // delete vertex
                it = surface.refs.erase(it);
                cleaned = true;
            }
            else if (it->collinear) // TODO: check if shared by other surfaces
            {
                // delete vertex
                it = surface.refs.erase(it);
                cleaned = true;
            }
            else
                ++it;
        }

        if (surface.refs.size() < 3)
        {
            // delete surface
            object.surfaces.erase(object.surfaces.begin() + i);
            --i;
            cleaned = true;
        }
    }

    // split non-coplanar quads into 2 triangles
    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        if (!object.surfaces[i].coplanar && object.surfaces[i].refs.size() == 4)
        {
            Surface surface;

            surface.flags = object.surfaces[i].flags;
            if (!object.surfaces[i].mats.empty())
                surface.mats.push_back(object.surfaces[i].mats.back());
            surface.refs.push_back(object.surfaces[i].refs[2]);
            surface.refs.push_back(object.surfaces[i].refs[3]);
            surface.refs.push_back(object.surfaces[i].refs[0]);

            object.surfaces.insert(object.surfaces.begin() + i + 1, surface);

            // remove last vertex of quad
            object.surfaces[i].refs.pop_back();

            // skip inserted surface
            i++;
        }
    }

    // remove duplicate surfaces
    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        for (size_t j = i + 1; j < object.surfaces.size(); ++j)
        {
            if (object.surfaces[i].flags != object.surfaces[j].flags)
                continue;

            if (object.surfaces[i].mats != object.surfaces[j].mats)
                continue;

            if (object.sameSurface(i, j, Difference::None))
            {
                object.surfaces.erase(object.surfaces.begin() + j);
                --j;
                cleaned = true;
            }
        }
    }

    return cleaned;
}

void AC3D::dump(DumpType dump_type) const
{
    for (size_t i = 0; i < m_objects.size(); i++)
    {
        m_objects[i].dump(dump_type, i, 0);
    }
}

bool AC3D::merge(const AC3D &ac3d)
{
    if (m_objects.size() != 1 || m_objects[0].type.type != "world" ||
        ac3d.m_objects.size() != 1 || ac3d.m_objects[0].type.type != "world")
    {
        return false;
    }

    const size_t num_materials = m_materials.size();
    const size_t num_kids = m_objects[0].kids.size();

    m_materials.insert(m_materials.end(), ac3d.m_materials.begin(), ac3d.m_materials.end());
    m_objects[0].kids.insert(m_objects[0].kids.end(), ac3d.m_objects[0].kids.begin(), ac3d.m_objects[0].kids.end());

    // fix up materials
    for (size_t i = num_kids; i < m_objects[0].kids.size(); i++)
    {
        m_objects[0].kids[i].incrementMaterialIndex(num_materials);
    }

    return true;
}

void AC3D::Object::incrementMaterialIndex(size_t num_materials)
{
    if (type.type == "poly")
    {
        for (auto &surface : surfaces)
        {
            if (!surface.mats.empty())
                surface.mats[0].mat += num_materials;
        }
    }
    else
    {
        for (auto &kid : kids)
            kid.incrementMaterialIndex(num_materials);
    }
}

void AC3D::Object::transform(const Matrix &currentMatrix)
{
    Matrix thisMatrix;

    if (!locations.empty())
    {
        thisMatrix.setLocation(locations.back().location);
        locations.clear();
        matrix.setLocation({ 0, 0, 0 });
    }

    if (!rotations.empty())
    {
        thisMatrix.setRotation(rotations.back().rotation);
        rotations.clear();
        matrix.setRotation({1, 0, 0, 0, 1, 0, 0, 0, 1});
    }

    const Matrix newMatrix = thisMatrix.multiply(currentMatrix);

    if (type.type == "poly")
    {
        for (auto &vertex : vertices)
        {
            newMatrix.transformPoint(vertex.vertex);

            if (vertex.has_normal)
                newMatrix.transformNormal(vertex.normal);
        }
    }
    else
    {
        for (auto &kid : kids)
            kid.transform(newMatrix);
    }
}

void AC3D::transform(const Matrix &matrix)
{
    for (auto & object : m_objects)
        object.transform(matrix);
}

bool AC3D::Object::splitPolygons()
{
    bool changed = false;

    if (type.type == "poly")
    {
        for (size_t i = 0; i < surfaces.size(); ++i)
        {
            const size_t size = surfaces[i].refs.size();

            if (size > 3)
            {
                // clear flags
                for (auto &ref : surfaces[i].refs)
                {
                    ref.collinear = false;
                    ref.duplicate = false;
                }

                for (size_t j = 2; j < size - 1; j++)
                {
                    Surface surface;

                    surface.flags = surfaces[i].flags;
                    if (!surfaces[i].mats.empty())
                        surface.mats.push_back(surfaces[i].mats.back());
                    surface.refs.push_back(surfaces[i].refs[j]);
                    surface.refs.push_back(surfaces[i].refs[j + 1]);
                    surface.refs.push_back(surfaces[i].refs[0]);

                    const size_t index = i + j - 1;
                    if (index < surfaces.size())
                        surfaces.insert(surfaces.begin() + index, surface);
                    else
                        surfaces.push_back(surface);
                }

                surfaces[i].refs.resize(3);
                surfaces[i].coplanar = true;
                surfaces[i].concave = false;

                // skip inserted surface
                i += (size - 2);

                changed = true;
            }
        }

        if (changed)
            numsurf.number = static_cast<int>(surfaces.size());
    }
    else
    {
        for (auto &kid : kids)
            changed |= kid.splitPolygons();
    }

    return changed;
}

void AC3D::flatten()
{
    const Matrix matrix;

    transform(matrix);

    //TODO flatten the object hiearchy
}

bool AC3D::splitPolygons()
{
    bool changed = false;

    for (auto &object : m_objects)
        changed |= object.splitPolygons();

    return changed;
}

void AC3D::removeObjects(const RemoveInfo &remove_info)
{
    for (auto &object : m_objects)
        object.removeKids(remove_info);
}

bool AC3D::Object::sameTextures(const Object &object) const
{
    if (object.textures.size() != textures.size())
        return false;

    for (size_t i = 0; i < textures.size(); ++i)
    {
        if (textures[i].name != object.textures[i].name)
            return false;
    }

    return true;
}

bool AC3D::Object::addObject(const Object &object)
{
    if (!sameTextures(object))
    {
        std::cerr << "Couldn't add object: different texture" << std::endl;
        return false;
    }

    const size_t vertex_offset = vertices.size();
    const size_t surface_offset = surfaces.size();

    // append new vertices
    vertices.insert(vertices.end(), object.vertices.begin(), object.vertices.end());
    numvert.number = static_cast<int>(vertices.size());

    // append new surfaces
    surfaces.insert(surfaces.end(), object.surfaces.begin(), object.surfaces.end());
    numsurf.number = static_cast<int>(surfaces.size());

    // adjust surface ref indexes
    for (size_t i = surface_offset; i < surfaces.size(); i++)
    {
        for (auto &ref : surfaces[i].refs)
        {
            ref.index += vertex_offset;
        }
    }

    return true;
}

void AC3D::combineTexture(const Object &object, std::vector<Object> &objects, std::vector<Object> &transparent_objects)
{
    if (object.type.type == "poly")
    {
        if (hasTransparentTexture(object))
        {
            for (auto &obj : transparent_objects)
            {
                if (obj.kids[0].sameTextures(object))
                {
                    obj.kids.push_back(object);
                    return;
                }
            }
            Object group;
            group.type.type = "group";
            transparent_objects.push_back(group);
            std::string name("transparent_group");
            name.append(std::to_string(transparent_objects.size()));
            Name quoted_name;
            quoted_name.name = quoted_string(name);
            transparent_objects.back().names.emplace_back(quoted_name);
            transparent_objects.back().kids.push_back(object);
            return;
        }

        for (auto &obj : objects)
        {
            if (obj.sameTextures(object))
            {
                obj.addObject(object);
                return;
            }
        }
        objects.push_back(object);
        if (m_rename_combine_texture)
        {
            std::string name("object");
            name.append(std::to_string(objects.size()));
            if (objects.back().names.size() == 1)
                objects.back().names[0].name = quoted_string(name);
        }
        return;
    }

    if (object.type.type == "group" || object.type.type == "world")
    {
        for (const auto &kid : object.kids)
            combineTexture(kid, objects, transparent_objects);
    }
}

void AC3D::combineTexture()
{
    std::chrono::system_clock::time_point start;

    if (m_show_times)
    {
        std::cout << "combineTexture starting" << std::endl;
        start = std::chrono::system_clock::now();
    }

    flatten();

    std::vector<Object> new_objects;
    std::vector<Object> new_transparent_objects;

    for (const auto &object : m_objects)
        combineTexture(object, new_objects, new_transparent_objects);

    Object &world = m_objects[0];

    world.kids.clear();

    Object opaque;
    opaque.type.type = "group";
    Name opaque_name;
    opaque_name.name = quoted_string("OPAQUE");
    opaque.names.emplace_back(opaque_name);
    world.kids.push_back(opaque);
    world.kids[0].kids.insert(world.kids[0].kids.begin(), new_objects.begin(), new_objects.end());

    Object transparent;
    transparent.type.type = "group";
    Name transparent_name;
    transparent_name.name = quoted_string("TRANSPARENT");
    transparent.names.emplace_back(transparent_name);
    world.kids.push_back(transparent);
    world.kids[1].kids.insert(world.kids[1].kids.end(), new_transparent_objects.begin(), new_transparent_objects.end());

    if (m_show_times)
    {
        const std::chrono::system_clock::time_point end = std::chrono::system_clock::now();
        std::cout << "combineTexture done: duration: " << getDuration(start, end) << std::endl;
    }
}

void AC3D::addPoly(std::vector<Poly> &polys, Object &object, const Matrix &matrix)
{
    if (object.type.type == "poly")
    {
        Matrix newMatrix = matrix;
        newMatrix.multiply(object.matrix);
        polys.emplace_back(&object, newMatrix);
    }
    else if (object.type.type == "group" || object.type.type == "world")
    {
        Matrix newMatrix = matrix;
        newMatrix.multiply(object.matrix);
        for (auto &kid : object.kids)
            addPoly(polys, kid, newMatrix);
    }
}

void AC3D::fixOverlapping2SidedSurface()
{
    std::vector<Poly> polys;
    const Matrix matrix;

    for (auto &world : m_objects)
        addPoly(polys, world, matrix);

    if (polys.empty())
        return;

    std::set<Surface *> surfaces;

    for (size_t i = 0; i < (polys.size() - 1); ++i)
    {
        for (size_t j = i + 1; j < polys.size(); ++j)
            fixOverlapping2SidedSurface(polys[i], polys[j], surfaces);
    }

    for (auto *surface : surfaces)
    {
        if (!surface->isDoubleSided())
            continue;

        if (surface->isPolygon())
        {
            if (surface->isSmoothShaded())
                surface->flags = 0x10;
            else
                surface->flags = 0x00;
        }
        else if (surface->isTriangleStrip())
        {
            if (surface->isSmoothShaded())
                surface->flags = 0x14;
            else
                surface->flags = 0x04;
        }
    }
}

void AC3D::fixOverlapping2SidedSurface(const Poly &object1, const Poly &object2, std::set<Surface *> &surfaces)
{
    for (auto &surface1 : object1.object->surfaces)
    {
        for (auto &surface2 : object2.object->surfaces)
        {
            if (surface1.isDoubleSided() || surface2.isDoubleSided())
            {
                if ((surface1.isPolygon() || surface1.isTriangleStrip()) &&
                    (surface2.isPolygon() || surface2.isTriangleStrip()))
                {
                    if (surface1.isPolygon() && surface1.refs.size() >= 3 &&
                        surface2.isPolygon() && surface2.refs.size() >= 3)
                    {
                        for (size_t i = 1; i < (surface1.refs.size() - 1); i++)
                        {
                            std::array<Point3, 3> triangle1{ object1.object->vertices[surface1.refs[0].index].vertex,
                                                             object1.object->vertices[surface1.refs[i].index].vertex,
                                                             object1.object->vertices[surface1.refs[i + 1].index].vertex };

                            if (degenerate(triangle1))
                                continue;

                            for (auto &triangle : triangle1)
                                object1.matrix.transformPoint(triangle);

                            for (size_t j = 1; j < (surface2.refs.size() - 1); j++)
                            {
                                std::array<Point3, 3> triangle2{ object2.object->vertices[surface2.refs[0].index].vertex,
                                                                 object2.object->vertices[surface2.refs[j].index].vertex,
                                                                 object2.object->vertices[surface2.refs[j + 1].index].vertex };

                                if (degenerate(triangle2))
                                    continue;

                                for (auto &triangle : triangle2)
                                    object2.matrix.transformPoint(triangle);

                                if (trianglesOverlap(triangle1, triangle2))
                                {
                                    surfaces.insert(&surface1);
                                    surfaces.insert(&surface2);
                                }
                            }
                        }
                    }
                    else if (surface1.isTriangleStrip() && surface2.isTriangleStrip())
                    {
                        for (size_t i = 2; i < surface1.refs.size(); i++)
                        {
                            std::array < Point3, 3> triangle1;

                            if ((i & 1u) == 0)
                            {
                                triangle1 = { object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }
                            else // reverse winding to match drawing order
                            {
                                triangle1 = { object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }

                            for (auto &triangle : triangle1)
                                object1.matrix.transformPoint(triangle);

                            if (!degenerate(triangle1))
                            {
                                for (size_t j = 2; j < surface2.refs.size(); j++)
                                {
                                    std::array < Point3, 3> triangle2;

                                    if ((i & 1u) == 0)
                                    {
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }
                                    else // reverse winding to match drawing order
                                    {
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }

                                    if (!degenerate(triangle2))
                                    {
                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            surfaces.insert(&surface1);
                                            surfaces.insert(&surface2);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (surface1.isPolygon() && surface2.isTriangleStrip())
                    {
                        if (surface1.refs.size() >= 3)
                        {
                            for (size_t i = 1; i < (surface1.refs.size() - 1); i++)
                            {
                                std::array<Point3, 3> triangle1{ object1.object->vertices[surface1.refs[0].index].vertex,
                                                                 object1.object->vertices[surface1.refs[i].index].vertex,
                                                                 object1.object->vertices[surface1.refs[i + 1].index].vertex };

                                if (degenerate(triangle1))
                                    continue;

                                for (auto &triangle : triangle1)
                                    object1.matrix.transformPoint(triangle);

                                for (size_t j = 2; j < surface2.refs.size(); j++)
                                {
                                    std::array < Point3, 3> triangle2;

                                    if ((i & 1u) == 0)
                                    {
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }
                                    else // reverse winding to match drawing order
                                    {
                                        triangle2 = { object2.object->vertices[surface2.refs[j - 1].index].vertex,
                                                      object2.object->vertices[surface2.refs[j - 2].index].vertex,
                                                      object2.object->vertices[surface2.refs[j].index].vertex };
                                    }

                                    if (!degenerate(triangle2))
                                    {
                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            surfaces.insert(&surface1);
                                            surfaces.insert(&surface2);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else if (surface1.isTriangleStrip() && surface2.isPolygon())
                    {
                        for (size_t i = 2; i < surface1.refs.size(); i++)
                        {
                            std::array < Point3, 3> triangle1;

                            if ((i & 1u) == 0)
                            {
                                triangle1 = { object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }
                            else // reverse winding to match drawing order
                            {
                                triangle1 = { object1.object->vertices[surface1.refs[i - 1].index].vertex,
                                              object1.object->vertices[surface1.refs[i - 2].index].vertex,
                                              object1.object->vertices[surface1.refs[i].index].vertex };
                            }

                            if (!degenerate(triangle1))
                            {
                                for (auto &triangle : triangle1)
                                    object1.matrix.transformPoint(triangle);

                                if (surface2.refs.size() >= 3)
                                {
                                    for (size_t j = 1; j < (surface2.refs.size() - 1); j++)
                                    {
                                        std::array<Point3, 3> triangle2{ object2.object->vertices[surface2.refs[0].index].vertex,
                                                                         object2.object->vertices[surface2.refs[j].index].vertex,
                                                                         object2.object->vertices[surface2.refs[j + 1].index].vertex };

                                        if (degenerate(triangle2))
                                            continue;

                                        for (auto &triangle : triangle2)
                                            object2.matrix.transformPoint(triangle);

                                        if (trianglesOverlap(triangle1, triangle2))
                                        {
                                            surfaces.insert(&surface1);
                                            surfaces.insert(&surface2);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

void AC3D::fixSurface2SidedOpaque()
{
    for (auto &object : m_objects)
        fixSurface2SidedOpaque(object);
}

void AC3D::fixSurface2SidedOpaque(Object &object)
{
    if (object.type.type == "poly")
    {
        if (hasOpaqueTexture(object))
        {
            for (auto &surface : object.surfaces)
            {
                if ((surface.isPolygon() || surface.isTriangleStrip()) && surface.isDoubleSided())
                {
                    //unsigned int flags = surface.flags;

                    surface.setSingleSided();

                    //std::cout << "changing " << object.getName() << " " << flags << " to " << surface.flags << std::endl;
                }
            }
        }
    }
    else if (object.type.type == "group" || object.type.type == "world")
    {
        for (auto &kid : object.kids)
            fixSurface2SidedOpaque(kid);
    }
}

bool AC3D::hasOpaqueTexture(const Object &object)
{
    if (object.textures.empty() || object.textures[0].name.empty())
        return false;

    const std::map<std::string, bool>::iterator it = m_transparent_textures.find(object.textures[0].path);

    if (it != m_transparent_textures.end())
        return !it->second;

    const bool transparent = object.hasTransparentTexture();

    m_transparent_textures[object.textures[0].path] = transparent;

    return !transparent;
}

bool AC3D::hasTransparentTexture(const Object &object)
{
    if (object.textures.empty() || object.textures[0].name.empty())
        return false;

    const std::map<std::string, bool>::iterator it = m_transparent_textures.find(object.textures[0].path);

    if (it != m_transparent_textures.end())
        return it->second;

    const bool transparent = object.hasTransparentTexture();

    m_transparent_textures[object.textures[0].path] = transparent;

    return transparent;
}

bool AC3D::Object::hasTransparentTexture() const
{
    if (textures.empty() || textures[0].name.empty())
        return false;

    // try to read the texture file first
    FILE *fp = fopen(textures[0].path.c_str(), "rb");
    if (!fp)
    {
        std::cout << "guessing texture type: " << textures[0].path.c_str() << std::endl;

        // guess based on texture name
        return (textures[0].name.find("_n.") != std::string::npos ||
                textures[0].name.find("tree") != std::string::npos ||
                textures[0].name.find("trans-") != std::string::npos ||
                textures[0].name.find("arbor") != std::string::npos);
    }

    const size_t number = 8;
    unsigned char header[number];

    if (fread(header, 1, number, fp) != number)
    {
        fclose(fp);
        std::cerr << "error reading png header: " << textures[0].path.c_str() << std::endl;
        return false;
    }

    const bool is_png = !png_sig_cmp(header, 0, number);
    if (!is_png)
    {
        fclose(fp);
        std::cerr << "invalid png header " << textures[0].path.c_str() << std::endl;
        return false;
    }
    png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png_ptr)
    {
        fclose(fp);
        return false;
    }
    png_infop info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
    {
        png_destroy_read_struct(&png_ptr, NULL, NULL);
        fclose(fp);
        return false;
    }
    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, number);
    png_read_info(png_ptr, info_ptr);

    png_uint_32 width, height;
    int bit_depth, color_type, interlace_type, compression_type, filter_method;
    png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type, &interlace_type, &compression_type, &filter_method);
    const int channels = png_get_channels(png_ptr, info_ptr);

    // look for RGBA with 4 8 bit channels
    // TODO support more formats?
    if (color_type != PNG_COLOR_TYPE_RGB_ALPHA || bit_depth != 8 || channels != 4)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        return false;
    }

    const size_t rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    png_uint_32 *image_data = (png_uint_32 *)malloc(rowbytes * height);

    if (image_data == NULL)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        return false;
    }

    png_bytepp row_pointers = (png_bytepp)malloc(sizeof(png_bytep) * height);

    if (row_pointers == NULL)
    {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        free(image_data);
        fclose(fp);
        return false;
    }
    for (png_uint_32 i = 0; i < height; ++i)
        row_pointers[i] = (png_byte*)image_data + i * rowbytes;

    png_set_rows(png_ptr, info_ptr, row_pointers);
    png_read_image(png_ptr, row_pointers);
    png_read_end(png_ptr, NULL);

    // check if alpha channel is opaque
    bool has_alpha = false;

    for (png_uint_32 i = 0; i < (width * height); i++)
    {
        const png_byte alpha = (image_data[i] >> 24) & 0x000000ff;
        if (alpha != 255)
        {
            has_alpha = true;
            break;
        }
    }

    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    free(image_data);
    free(row_pointers);
    fclose(fp);

#if 0
    std::cerr << textures[0].name << " color_type: " << color_type
              << " width: " << width
              << " height: " << height
              << " bit depth: " << bit_depth
              << " channels: " << channels
              << " has_alpha: " << has_alpha
              << std::endl;
#endif

    return has_alpha;
}

std::string AC3D::getTime(const std::chrono::time_point<std::chrono::system_clock> &time)
{
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(time.time_since_epoch()) % 1000;
    const auto local_time = std::chrono::system_clock::to_time_t(time);
    const std::tm bt = *std::localtime(&local_time);
    std::ostringstream oss;
    oss << std::put_time(&bt, "%a %b %d %H:%M:%S") << "." << std::setfill('0') << std::setw(3) << ms.count() << " " << std::put_time(&bt, "%p");
    return oss.str();
}

std::string AC3D::getDuration(const std::chrono::time_point<std::chrono::system_clock> &start,
                              const std::chrono::time_point<std::chrono::system_clock> &end)
{
    const std::chrono::duration<double> time_span = std::chrono::duration_cast<std::chrono::duration<double>>(end - start);
    const auto hrs = std::chrono::duration_cast<std::chrono::hours>(time_span);
    const auto mins = std::chrono::duration_cast<std::chrono::minutes>(time_span - hrs);
    const auto secs = std::chrono::duration_cast<std::chrono::seconds>(time_span - hrs - mins);
    const auto ms = std::chrono::duration_cast<std::chrono::microseconds>(time_span - hrs - mins - secs);
    std::ostringstream oss;
    if (hrs.count() > 0)
        oss << hrs.count() << " hours ";
    if (mins.count() > 0)
        oss << mins.count() << " minutes ";
    oss << secs.count() << "." << std::setfill('0') << std::setw(6) << ms.count() << " seconds";

    return oss.str();
}
