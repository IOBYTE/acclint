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
#include <algorithm>
#include <cmath>

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
    std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
    std::streampos end = buf->pubseekoff(0, std::ios_base::end, std::ios_base::in);
    buf->pubseekpos(pos, std::ios_base::in);
    return end != pos;
}

std::string getTrailing(const std::istringstream &s)
{
    std::streambuf *buf = s.rdbuf();
    std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
    buf->pubseekpos(pos, std::ios_base::in);
    return s.str().substr(pos);
}

void showLine(std::istringstream &in)
{
    std::cerr << in.str() << std::endl;

    std::streambuf *buf = in.rdbuf();
    std::streampos pos = buf->pubseekoff(0, std::ios_base::cur, std::ios_base::in);
    buf->pubseekpos(pos, std::ios_base::in);

    for (size_t i = 0; i < pos; ++i)
        std::cerr << ' ';
    std::cerr << '^' << std::endl;
}

void showLine(std::istringstream &in, const std::streampos &pos)
{
    std::cerr << in.str() << std::endl;

    for (size_t i = 0; i < pos; ++i)
        std::cerr << ' ';
    std::cerr << '^' << std::endl;
}

void showLine(std::istream &in, const std::streampos &pos)
{
    std::streampos current = in.tellg();
    std::string line;

    in.seekg(pos);
    std::getline(in, line);

    // remove CR
    if (line.back() == '\r')
        line.pop_back();
    std::cerr << line << std::endl;
    std::cerr << '^' << std::endl;

    in.seekg(current);
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
                warning() << "blank line" << std::endl;
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
    if (line_number)
        std::cerr << m_file << ":" << line_number << " warning: ";
    else
        std::cerr << m_file << ":" << m_line_number << " warning: ";
    return std::cerr;
}

std::ostream &AC3D::error(size_t line_number)
{
    m_errors++;
    if (line_number)
        std::cerr << m_file << ":" << line_number << " error: ";
    else
        std::cerr << m_file << ":" << m_line_number << " error: ";
    return std::cerr;
}

std::ostream &AC3D::note(size_t line_number)
{
    std::cerr << m_file << ":" << line_number << " note: ";
    return std::cerr;
}

void AC3D::checkTrailing(std::istringstream &iss)
{
    if (!m_trailing_text)
        return;

    std::streampos pos = iss.tellg();
    if (hasTrailing(iss))
    {
        warning() << "trailing text: \"" << getTrailing(iss) << "\"" << std::endl;
        showLine(iss, pos);
    }
}

bool AC3D::readRef(std::istringstream &in, AC3D::Ref &ref)
{
    in >> ref.index;

    if (!in)
    {
        error() << "reading index" << std::endl;
        showLine(in);
        return false;
    }

    std::array<double,2> uv;

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
                    warning() << "trailing text: \"" << trailing << "\"" << std::endl;
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
                                            warning() << "trailing text: \"" << trailing << "\"" << std::endl;
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
                                            warning() << "trailing text: \"" << trailing << "\"" << std::endl;
                                            showLine(in, pos);
                                        }
                                    }
                                    else
                                    {
                                        error() << "reading forth texture cordinate: \"" << trailing << "\"" << std::endl;
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
                                    warning() << "trailing text: \"" << trailing << "\"" << std::endl;
                                    showLine(in, pos);
                                }
                            }
                            else
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
                            warning() << "trailing text: \"" << trailing << "\"" << std::endl;
                            showLine(in, pos);
                        }
                    }
                    else
                    {
                        error() << "reading second texture cordinate: \"" << trailing << "\"" << std::endl;
                        showLine(in);
                    }
                }
            }
        }
    }
    else
    {
        error() << "reading texture cordinate" << std::endl;
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
        int surf = 0;

        iss >> std::ws;
        std::streampos pos = iss.tellg();
        iss >> std::hex >> surf >> std::dec;

        if (iss)
        {
            if (!surface.flags.empty())
            {
                warning() << "multiple SURF" << std::endl;
                showLine(iss, 0);
            }

            // TODO check flags here

            surface.flags.push_back(surf);

            checkTrailing(iss);
        }
        else
        {
            error() << "reading type" << std::endl;
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

    if (token == mat_token)
    {
        size_t mat;

        iss >> std::ws;
        std::streampos pos = iss.tellg();
        iss >> mat;

        if (iss)
        {
            setMaterialUsed(mat);

            if (!surface.mat.empty())
            {
                warning() << "multiple mat" << std::endl;
                showLine(iss, 0);
            }

            if (mat >= m_materials.size())
            {
                if (m_invalid_material_index)
                {
                    error() << "invalid material index: " << mat << " of "
                            << m_materials.size() << std::endl;
                    showLine(iss, pos);
                }
            }

            surface.mat.push_back(mat);

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
        int refs = 0;

        iss >> refs;

        if (iss)
            checkTrailing(iss);
        else
        {
            error() << "reading refs count" << std::endl;
            showLine(iss);
        }

        for (int j = 0; j < refs; ++j)
        {
            if (getLine(in))
            {
                Ref ref;

                ref.line_number = m_line_number;
                ref.line_pos = m_line_pos;

                std::istringstream iss1(m_line);

                if (readRef(iss1, ref))
                {
                    if (ref.index >= object.vertices.size())
                    {
                        error() << "invalid vertex index: " << ref.index << " of "
                                << object.vertices.size() << std::endl;
                        showLine(iss, 0);
                    }
                    else
                        object.vertices[ref.index].used = true;
                }

                if (ref.coordinates.size() > 1 && ref.coordinates.size() > object.textures.size())
                    error() << "more texture coordinates: " << ref.coordinates.size()
                            << " than textures: " << object.textures.size() << std::endl;

                surface.refs.push_back(ref);
            }
        }

        checkDuplicateSurfaceVertices(in, object, surface);
    }
    else
    {
        error() << "invalid surface" << std::endl;
        return false;
    }

    return true;
}

bool AC3D::sameVertex(const Vertex &vertex1, const Vertex &vertex2) const
{
    if (vertex1.vertex != vertex2.vertex)
        return false;

    if (vertex1.has_normal && vertex1.normal != vertex2.normal)
        return false;

    return true;
}

void AC3D::writeSurface(std::ostream &out, const Surface &surface) const
{
    if (!surface.flags.empty())
        out << "SURF 0x" << std::hex << surface.flags[0] << std::dec << newline(m_crlf);
    if (!surface.mat.empty())
        out << "mat " << surface.mat[0] << newline(m_crlf);
    out << "refs " << surface.refs.size() << newline(m_crlf);
    for (const auto &ref : surface.refs)
        writeRef(out, ref);
}

bool AC3D::readHeader(std::istream &in)
{
    if (!getLine(in))
    {
        error(1) << "missing AC3D" << std::endl;
        return false;
    }

    std::istringstream iss(m_line);

    if (m_line.compare(0, 4, "AC3D") != 0)
    {
        error(1) << "not and AC3D file" << std::endl;
        showLine(iss, 0);
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
            warning(1) << "trailing text: \"" << m_line.substr(5) << "\"" << std::endl;
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

        if (size)
        {
            std::getline(in, m_line);
            m_line_number++;
            data = m_line;

            while (data.size() < size)
            {
                data += '\n'; // add a newline removed by getline

                std::getline(in, m_line);
                m_line_number++;
                data += m_line;
            }

            if (data.size() > size)
            {
                if (!(data.back() == '\r' && data.size() == (size + 1)))
                {
                    if (m_trailing_text)
                    {
                        warning() << "trailing text: \"" << data.substr(size) << "\"" << std::endl;
                        std::istringstream iss1(m_line);
                        showLine(iss1, m_line.size() - (data.size() - size));
                    }
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
    out << data << newline(m_crlf);
}

bool AC3D::readColor(std::istringstream &in, std::array<double,3> &color, const std::string &expected, const std::string &next)
{
    bool status = true;
    for (size_t i = 0; i < 3; ++i)
    {
        in >> std::ws;

        std::streampos pos = in.tellg();
        double value;

        in >> value;

        if (!in)
        {
            if (in.eof())
            {
                error() << "invalid " << expected << std::endl;
                showLine(in);
                return false;
            }
            else
            {
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
        }
        else if (value < 0.0 || value > 1.0)
        {
            if (m_invalid_material)
            {
                warning() << "invalid material " << expected << ": " << value << " range: 0 to 1" << std::endl;
                showLine(in, pos);
            }
        }

        color[i] = value;
    }

    return status;
}

bool AC3D::readTypeAndColor(std::istringstream &in, std::array<double,3> &color, const std::string &expected, const std::string &next)
{
    in >> std::ws;

    std::streampos pos = in.tellg();
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
        double number;
        iss >> number;
        if (iss)
        {
            error() << "reading " << expected << std::endl;
            showLine(in, pos);
            return readTypeAndColor(in, color, expected, next);
        }

        if (m_invalid_material)
        {
            warning() << "invalid material " << expected << ": " << actual << std::endl;
            showLine(in, pos);
        }
    }

    return readColor(in, color, expected, next);
}

bool AC3D::readValue(std::istringstream &in, double &value, const std::string &expected, double min, double max, bool is_float)
{
    in >> std::ws;
    std::streampos pos = in.tellg();
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
                    warning() << "floating point " << expected << ": " << value_string << std::endl;
                    showLine(in, pos);
                }
            }

            if (value < min || value > max)
            {
                if (m_invalid_material)
                {
                    warning() << "invalid material " << expected << ": " << value << " range: "
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
    std::streampos pos = in.tellg();
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
        double number;
        iss >> number;
        if (iss)
        {
            error() << "reading " << expected << std::endl;
            showLine(in, pos);
            return readTypeAndValue(in, value, expected, next, min, max, is_float);
        }

        if (m_invalid_material)
        {
            warning() << "invalid material " << expected << ": " << actual << std::endl;
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
            readData(iss, in, material.data);
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
            error() << "invalid token: " << token << std::endl;
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
        if (!material.data.empty())
            writeData(out, material.data);
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
    int numsurf = 0;
    size_t numsurf_line_number = 0;
    std::string numsurf_line;
    size_t object_line = m_line_number;
    iss >> std::ws;
    std::streampos pos = iss.tellg();
    iss >> object.type;

    if (!iss)
    {
        error() << "reading type" << std::endl;
        showLine(iss);
    }
    else
    {
        if (object.type != world_token && object.type != group_token &&
            object.type != poly_token && object.type != light_token)
        {
            if (icasecmp(object.type, world_token) || icasecmp(object.type, group_token) ||
                icasecmp(object.type, poly_token) || icasecmp(object.type, light_token))
            {
                warning() << "type should be lowercase: " << object.type << std::endl;
                showLine(iss, pos);
            }
            else
            {
                warning() << "unknown object type: " << object.type << std::endl;
                showLine(iss, pos);
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
            iss1 >> object.name;

            if (iss1)
                checkTrailing(iss1);
            else
            {
                error() << "reading name" << std::endl;
                showLine(iss1);
            }
        }
        else if (token == data_token)
        {
            readData(iss1, in, object.data);
        }
        else if (token == texture_token)
        {
            Texture texture;

            iss1 >> texture.name;

            if (iss1)
            {
                if (hasTrailing(iss1))
                {
                    std::string trailing = getTrailing(iss1);
                    iss1 >> texture.type;
                    if (iss1)
                    {
                        if (hasTrailing(iss1))
                        {
                            if (m_trailing_text)
                                warning() << "trailing text: \"" << getTrailing(iss1) << "\"" << std::endl;
                        }
                    }
                    else
                    {
                        if (m_trailing_text)
                            warning() << "trailing text: \"" << getTrailing(iss1) << "\"" << std::endl;
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

            iss1 >> texrep.texrep;

            if (iss1)
            {
                if (!object.texreps.empty())
                {
                    warning() << "multiple texrep" << std::endl;
                    showLine(iss1, 0);
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

            iss1 >> texoff.texoff;

            if (iss1)
            {
                if (!object.texoffs.empty())
                {
                    warning() << "multiple texoff" << std::endl;
                    showLine(iss1, 0);
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
        }
        else if (token == crease_token)
        {
            Crease crease;

            iss1 >> crease.crease;

            if (iss1)
            {
                if (!object.creases.empty())
                {
                    warning() << "multiple crease" << std::endl;
                    showLine(iss1, 0);
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

            iss1 >> rotation.rotation;

            if (iss1)
            {
                if (!object.rotations.empty())
                {
                    warning() << "multiple rot" << std::endl;
                    showLine(iss1, 0);
                }

                object.rotations.push_back(rotation);

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

            iss1 >> location.location;

            if (iss1)
            {
                if (!object.locations.empty())
                {
                    warning() << "multiple loc" << std::endl;
                    showLine(iss1, 0);
                }

                object.locations.push_back(location);

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
            iss1 >> object.url;

            checkTrailing(iss1);
        }
        else if (token == locked_token)
        {
        }
        else if (token == hidden_token)
        {
        }
        else if (token == folded_token)
        {
        }
        else if (token == numvert_token)
        {
            int numvert = 0;

            iss1 >> numvert;

            if (iss1)
                checkTrailing(iss1);
            else
            {
                error() << "reading number of verticies" << std::endl;
                showLine(iss1);
                continue;
            }

            for (int i = 0; i < numvert; ++i)
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
                            std::streampos pos2 = iss2.tellg();
                            std::string trailing = getTrailing(iss2);
                            if (m_is_ac)
                            {
                                if (m_trailing_text)
                                {
                                    warning() << "trailing text: \"" << trailing << "\"" << std::endl;
                                    showLine(iss2, pos2);
                                }
                            }
                            else
                            {
                                iss2 >> vertex.normal;
                                if (iss2)
                                {
                                    vertex.has_normal = true;

                                    checkTrailing(iss2);
                                }
                                else
                                {
                                    if (isWhitespace(trailing))
                                    {
                                        if (m_trailing_text)
                                            warning() << "trailing text: \"" << trailing << "\"" << std::endl;
                                    }
                                    else
                                    {
                                        error() << "reading normal" << std::endl;
                                        showLine(iss2);
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        std::streampos pos = iss2.tellg();
                        iss2.clear();
                        iss2.seekg(0, std::ios::beg);
                        std::string token1;
                        iss2 >> token1;
                        if (token1 == numsurf_token || token1 == kids_token)
                        {
                            error() << "missing vertex" << std::endl;
                            showLine(iss2, 0);
                            ungetLine(in);
                            break;
                        }
                        else
                        {
                            error() << "reading vertex" << std::endl;
                            showLine(iss2, pos == -1 ? static_cast<std::streampos>(0) : pos);
                        }
                    }

                    object.vertices.push_back(vertex);
                }
            }

            checkDuplicateVertices(in, object);
        }
        else if (token == numsurf_token)
        {
            numsurf_line_number = m_line_number;
            numsurf_line = m_line;
            numsurf = 0;

            iss1 >> numsurf;

            if (!iss1)
            {
                error() << "reading number of surfaces" << std::endl;
                continue;
            }

            checkTrailing(iss1);

            for (int i = 0; i < numsurf; ++i)
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
                size_t kids_line = m_line_number;

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
                        else
                        {
                            error() << "invalid token: " << token1 << std::endl;
                            showLine(iss2, 0);
                        }
                    }
                    else
                    {
                        if (m_missing_kids)
                            warning(kids_line) << "missing kids: only " << i << " out of " << kids << " kids found" << std::endl;
                        return false;
                    }
                }
                m_level--;
            }
            break;
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
            error() << "found more SURF than specified: " << numsurf << std::endl;
            showLine(iss1, 0);

            Surface surface;

            if (readSurface(in, surface, object, false))
                object.surfaces.push_back(surface);
        }
        else
        {
            error() << "invalid token: " << token << std::endl;
            showLine(iss1, 0);
        }
    }

    if (object.empty() && m_empty_object)
    {
        warning(object_line) << "empty object: " << object.name << std::endl;
        showLine(iss, 0);
    }

    checkUnusedVertex(in, object);
    checkDuplicateSurfaces(in, object);

#if defined(CHECK_TRIANGLE_STRIPS)
    struct Triangle
    {
        std::array<size_t,3> vertices{ 0, 0, 0 };
        size_t surface = 0;
        size_t triangle = 0;
        bool degenerate = false;
        bool duplicate = false;
    };

    std::vector<Triangle> triangles;

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        if ((object.surfaces[i].flags.back() & 4) == 4)
        {
            for (size_t j = 0; j < object.surfaces[i].refs.size() - 2; ++j)
            {
                bool degenerate = false;

                if (object.surfaces[i].refs[j].index >= object.vertices.size() ||
                    object.surfaces[i].refs[j + 1].index >= object.vertices.size() ||
                    object.surfaces[i].refs[j + 2].index >= object.vertices.size())
                    continue;

                if (object.vertices[object.surfaces[i].refs[j].index].vertex == object.vertices[object.surfaces[i].refs[j + 1].index].vertex ||
                    object.vertices[object.surfaces[i].refs[j].index].vertex == object.vertices[object.surfaces[i].refs[j + 2].index].vertex ||
                    object.vertices[object.surfaces[i].refs[j + 1].index].vertex == object.vertices[object.surfaces[i].refs[j + 2].index].vertex)
                {
                    std::cout << "surface " << i << " degenerate triangle skipped: "
                              << object.surfaces[i].refs[j].index << " " << object.vertices[object.surfaces[i].refs[j].index].vertex << "  "
                              << object.surfaces[i].refs[j + 1].index << " " << object.vertices[object.surfaces[i].refs[j + 1].index] << "  "
                              << object.surfaces[i].refs[j + 2].index << " " << object.vertices[object.surfaces[i].refs[j + 2].index] << std::endl;
                    degenerate = true;
                }

                Triangle triangle;
                triangle.surface = i;
                triangle.triangle = j;
                triangle.degenerate = degenerate;
                if ((j & 1) == 0)
                {
                    triangle.vertices[0] = object.surfaces[i].refs[j].index;
                    triangle.vertices[1] = object.surfaces[i].refs[j + 1].index;
                    triangle.vertices[2] = object.surfaces[i].refs[j + 2].index;
                }
                else
                {
                    triangle.vertices[0] = object.surfaces[i].refs[j + 1].index;
                    triangle.vertices[1] = object.surfaces[i].refs[j].index;
                    triangle.vertices[2] = object.surfaces[i].refs[j + 2].index;
                }

                triangles.push_back(triangle);
            }
        }
    }

    if (!triangles.empty())
    {
        std::cout << triangles.size() << " triangles" << std::endl;

        for (size_t i = 0; i < triangles.size(); ++i)
        {
            for (size_t j = i + 1; j < triangles.size(); ++j)
            {
                size_t duplicates = 0;

                for (size_t k = 0; k < 3; k++)
                {
                    for (size_t l = 0; l < 3; ++l)
                    {
                        if (!triangles[i].duplicate && !triangles[i].degenerate && !triangles[j].degenerate &&
                            sameVertex(object.vertices[triangles[i].vertices[k]], object.vertices[triangles[j].vertices[l]]))
                        {
                            duplicates++;
                        }
                    }
                }

                if (duplicates >= 3)
                {
                    triangles[j].duplicate = true;

                    std::cout << "surface " << triangles[i].surface << " triangle " << triangles[i].triangle << " and "
                              << "surface " << triangles[j].surface << " triangle " << triangles[j].triangle << " are duplicates" << std::endl;
                    std::cout << "    " << triangles[i].vertices[0] << "  " << triangles[j].vertices[0] << std::endl;
                    std::cout << "    " << triangles[i].vertices[1] << "  " << triangles[j].vertices[1] << std::endl;
                    std::cout << "    " << triangles[i].vertices[2] << "  " << triangles[j].vertices[2] << std::endl;
                }
            }
        }
    }
#endif

    return true;
}

bool AC3D::sameSurface(const Surface &surface1, const Surface &surface2, const Object &object) const
{
    if (surface1.refs.size() != surface2.refs.size() || surface1.refs.empty())
        return false;

    for (size_t i = 0; i < surface1.refs.size(); ++i)
    {
        // skip invalid vertex
        if (surface1.refs[i].index >= object.vertices.size() ||
            surface2.refs[i].index >= object.vertices.size())
            continue;

        if (!(surface1.refs[i].index == surface2.refs[i].index ||
            sameVertex(object.vertices[surface1.refs[i].index], object.vertices[surface2.refs[i].index])))
            return false;
    }

    return true;
}

void AC3D::writeObject(std::ostream &out, const Object &object) const
{
    out << "OBJECT " << object.type << newline(m_crlf);
    if (!object.name.empty())
        out << "name " << object.name << newline(m_crlf);
    if (!object.locations.empty())
        out << "loc " << object.locations.back().location << newline(m_crlf);
    if (!object.rotations.empty())
        out << "rot " << object.rotations.back().rotation << newline(m_crlf);
    if (!object.creases.empty())
        out << "crease " << object.creases.back().crease << newline(m_crlf);
    if (!object.data.empty())
        writeData(out, object.data);
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
    if (!object.vertices.empty())
    {
        out << "numvert " << object.vertices.size() << newline(m_crlf);
        for (const auto &vertex : object.vertices)
        {
            out << vertex.vertex;
            if (vertex.has_normal)
                out << ' ' << vertex.normal;
            out << newline(m_crlf);
        }
    }
    if (!object.surfaces.empty())
    {
        out << "numsurf " << object.surfaces.size() << newline(m_crlf);
        for (const auto &surface : object.surfaces)
            writeSurface(out, surface);
    }

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

    std::ifstream in(m_file);

    if (!in)
    {
        std::cerr << "Failed to read: \"" << m_file << "\"" << std::endl;
        return false;
    }

    std::string extension(".ac");

    if (m_file.size() > extension.size())
        m_is_ac = std::equal(m_file.begin() + m_file.size() - extension.size(), m_file.end(), extension.begin());

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
                Object object;
                readObject(iss, in, object);
                needMaterial = false;
                m_objects.push_back(object);
            }
            else
            {
                error() << "invalid token: " << token << std::endl;
                showLine(iss, 0);
            }
        }
        else if (token == OBJECT_token)
        {
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
        else
        {
            error() << "invalid token: " << token << std::endl;
            showLine(iss, 0);
        }
    }

    in.clear(); // clear eof so we can seek in file

    checkDuplicateMaterials(in);
    checkUnusedMaterial(in);

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
        for (size_t i = 0; i < m_materials.size(); ++i)
        {
            if (!m_materials[i].used)
            {
                warning(m_materials[i].line_number) << "unused material" << std::endl;
                showLine(in, m_materials[i].line_pos);
            }
        }
    }
}

void AC3D::checkDuplicateSurfaces(std::istream &in, const Object &object)
{
    if (!m_duplicate_surfaces)
        return;

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        for (size_t j = i + 1; j < object.surfaces.size(); ++j)
        {
            if (sameSurface(object.surfaces[i], object.surfaces[j], object))
            {
                warning(object.surfaces[j].line_number) << "duplicate surfaces" << std::endl;
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

    for (size_t i = 0; i < object.vertices.size(); i++)
    {
        if (!object.vertices[i].used)
        {
            warning(object.vertices[i].line_number) << "unused vertex" << std::endl;
            showLine(in, object.vertices[i].line_pos);
        }
    }
}

void AC3D::checkDuplicateSurfaceVertices(std::istream &in, const Object &object, const Surface &surface)
{
    if (!m_duplicate_surface_vertices)
        return;

    for (size_t i = 0; i < surface.refs.size(); ++i)
    {
        for (size_t j = i + 1; j < surface.refs.size(); ++j)
        {
            // skip invalid vertex
            if (surface.refs[i].index >= object.vertices.size() ||
                surface.refs[j].index >= object.vertices.size())
                continue;

            if (surface.refs[i].index == surface.refs[j].index ||
                sameVertex(object.vertices[surface.refs[i].index],
                           object.vertices[surface.refs[j].index]))
            {
                // triangle strips can have duplicates
                if (surface.flags.empty() || (surface.flags.back() & 0xf) != 4)
                {
                    warning(surface.refs[j].line_number) << "duplicate surface vertices" << std::endl;
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
            if (sameVertex(object.vertices[i], object.vertices[j]))
            {
                duplicates[j] = true;

                warning(object.vertices[j].line_number) << "duplicate verticies" << std::endl;
                showLine(in, object.vertices[j].line_pos);
                note(object.vertices[i].line_number) << "first instance" << std::endl;
                showLine(in, object.vertices[i].line_pos);
            }
        }
    }
}

bool AC3D::write(const std::string &file) const
{
    std::ofstream of(file, std::ofstream::binary);

    if (!of)
        return false;

    writeHeader(of, m_header);

    for (size_t i = 0; i < m_materials.size(); ++i)
        writeMaterial(of, m_materials[i]);

    for (size_t i = 0; i < m_objects.size(); ++i)
        writeObject(of, m_objects[i]);

    return true;
}

bool AC3D::sameMaterial(const Material &material1, const Material &material2) const
{
    return material1.name == material2.name && sameMaterialParameters(material1, material2);
}

bool AC3D::sameMaterialParameters(const Material &material1, const Material &material2) const
{
    return material1.rgb == material2.rgb &&
           material1.amb == material2.amb &&
           material1.emis == material2.emis &&
           material1.spec == material2.spec &&
           material1.shi == material2.shi &&
           material1.trans == material2.trans &&
           material1.data == material2.data;
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
    bool cleaned = false;

    cleaned |= cleanMaterials();
    cleaned |= cleanVertices();
    cleaned |= cleanSurfaces();
    cleaned |= cleanObjects();

    return cleaned;
}

bool clip(std::array<double,3> &values)
{
    bool clipped = false;

    for (auto &value : values)
    {
        if (value < 0.0)
        {
            value == 0.0;
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

bool AC3D::cleanMaterials()
{
    bool cleaned = false;

    for (auto &material : m_materials)
    {
        cleaned |= clip(material.rgb);
        cleaned |= clip(material.amb);
        cleaned |= clip(material.emis);
        cleaned |= clip(material.spec);

        double shi = std::round(material.shi);

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
                    duplicates[j] = true;
                    newIndex[j] = i;
                    // mark first instance used
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
                if (newIndex[j] > i)
                    newIndex[j]--;
            }
        }
    }

    for (size_t i = duplicates.size(); i > 0; --i)
    {
        size_t index = i - 1;

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

    for (size_t i = 0; i < objects.size(); ++i)
    {
        for (size_t j = 0; j < objects[i].surfaces.size(); ++j)
        {
            if (!objects[i].surfaces[j].mat.empty() &&
                objects[i].surfaces[j].mat.back() != indexes[objects[i].surfaces[j].mat.back()])
            {
                changed = true;

                // update surface with new index
                objects[i].surfaces[j].mat.back() = indexes[objects[i].surfaces[j].mat.back()];
            }
        }

        changed != cleanMaterials(objects[i].kids, indexes);
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
        cleaned |= cleanObjects(it->kids);

        if (it->empty())
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
    return cleanVertices(m_objects);
}

bool AC3D::cleanVertices(std::vector<Object> &objects)
{
    bool cleaned = false;

    for (size_t i = 0; i < objects.size(); ++i)
    {
        cleaned |= cleanVertices(objects[i]);
        cleaned |= cleanVertices(objects[i].kids);
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
            size_t index = object.surfaces[i].refs[j].index;

            if (index >= object.vertices.size())
                return false;

            if (info[index].duplicate)
            {
                size_t new_index = info[index].new_index;

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
    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        for (size_t j = 0; j < object.surfaces[i].refs.size(); j++)
            object.surfaces[i].refs[j].index = info[object.surfaces[i].refs[j].index].new_index;
    }

    return true;
}

bool AC3D::cleanSurfaces()
{
    return cleanSurfaces(m_objects);
}

bool AC3D::cleanSurfaces(std::vector<Object> &objects)
{
    bool cleaned = false;

    for (size_t i = 0; i < objects.size(); ++i)
    {
        cleaned |= cleanSurfaces(objects[i]);
        cleaned |= cleanSurfaces(objects[i].kids);
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
        size_t duplicate = 0;

        for (size_t j = 0; j < surface.refs.size(); ++j)
        {
            for (size_t k = j + 1; k < surface.refs.size(); ++k)
            {
                if (surface.refs[j].index == surface.refs[k].index ||
                    sameVertex(object.vertices[surface.refs[j].index],
                               object.vertices[surface.refs[k].index]))
                {
                    // triangle strips can have duplicates
                    if (surface.flags.empty() || (surface.flags.back() & 0xf) != 4)
                    {
                        // delete vertex
                        surface.refs.erase(surface.refs.begin() + k);
                        --k;
                        cleaned = true;
                    }
                }
            }
        }

        if (surface.refs.size() < 3)
        {
            // delete surface
            object.surfaces.erase(object.surfaces.begin() + i);
            --i;
            cleaned = true;
        }
    }

    for (size_t i = 0; i < object.surfaces.size(); ++i)
    {
        for (size_t j = i + 1; j < object.surfaces.size(); ++j)
        {
            if (sameSurface(object.surfaces[i], object.surfaces[j], object))
            {
                object.surfaces.erase(object.surfaces.begin() + j);
                --j;
                cleaned = true;
            }
        }
    }

    return cleaned;
}

