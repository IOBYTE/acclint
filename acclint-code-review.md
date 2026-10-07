# acclint code review — 2026-10-07

Scope: `ac3d.cpp` (10,916 lines), `ac3d.h`, `acclint.cpp`, as they are on your disk now, including everything fixed since the 2026-10-06 review. Third-party `triangleintersects.hpp` and `ya_getopt.*` were not reviewed.

Method: five reviewers each read one slice end to end and reproduced every suspicion against the current release build. I re-ran the reproductions for every item marked ✔.

- **✔** = I reproduced it myself.
- **R** = a reviewer reproduced it; the input is in the repro bundle.

Repro inputs are in `acclint-review-2-repros/<NN>-name/`, numbered to match the items; `NN/file` below is short for that folder. Numbering starts again at 1; the previous review's items are referred to as "old #n".

## What came back clean

- **ASan + UBSan over the whole suite:** 1043/1043 tests pass, no sanitizer reports.
- **Parser fuzzing:** about 12,000 mutated files (lines deleted, duplicated, swapped, truncated; counts changed; all options) through an ASan+UBSan build: no crash, hang or sanitizer report. CRLF and LF give identical diagnostics; blank lines shift line numbers exactly as they should.
- **`--fixKids`:** with random wrong counts, no object was lost or duplicated in 1,400 cases (old #6 holds). Items 19 and 35 are about objects put in the wrong place.
- **`triangulatePolygon`:** 110,000 random simple polygons (star, random, grid, collinear runs, keyholes; arbitrary 3D planes; up to 2 km from the origin). Every triangle lies inside and keeps the winding; areas add up. Roughly O(n²): 8,000 corners in 0.47 s.
- **Grid strip splitting, quad tree, `--stitchStrips`, `--rebuildStrips`:** geometry identical to a plain `-o` on every fixture.
- **Also sound:** `stitchTriangleStrips` padding, the `cleanVertices` remap, the `cleanMaterials` remap, the `cleanSurfaces` duplicate hash.
- **Compiler:** `-Wall -Wextra -Wpedantic` is clean apart from item 2. `-Wshadow` still flags only the lambdas in `makeTriangleStrips`. cppcheck is not installed in this environment and was not re-run.

---

## 1. Regressions from this round's fixes

**1. A gentle curve loses all its vertices on any `-o`** — `ac3d.cpp:6360–6404` (`checkCollinearSurfaceVertices`), removal in `cleanSurfaces` (`ac3d.cpp:8726`) ✔ — **high, caused by the old #11 fix** — **fixed**
- The coordinate-scale term added to `collinear()` treats a corner as straight if it is off the line by less than `equals()` resolution (2.4 mm at x = 5000). Each corner is tested against its original neighbours, and then every flagged ref is deleted at once, so the small deviations add up.
- `01/collinear_arc.ac`: a 50 m arc of radius 300 at x ≈ 5000, each corner bending 1.67 mm. 49 "collinear vertices"; `-o` writes `numvert 4` and the edge moves 1.04 m. Before the #11 fix the arc came through intact.
- Fix: decide each corner against the last corner kept (so removals cannot accumulate), or keep the coordinate term only for corners next to a doubled point and use the sine test alone elsewhere.

**2. `checkSurfacePolygonType` reads a possibly uninitialised `Point2`** — `ac3d.cpp:6764` ✔ — trivial — **fixed**
- gcc `-Wmaybe-uninitialized` on the `Point2 p` added for the corner list. `getVertex` has no `default:` in its switch. Initialise it (`Point2 p{}`).

## 2. Silent wrong output (written file is wrong, exit 0)

**3. `--flatten` applies parent and child transforms in the wrong order** — `ac3d.cpp:9524` (`Object::transform`) ✔ — **high** — found by two reviewers — **fixed**
- `thisMatrix.multiply(currentMatrix)` applies the parent before the child. `addPoly` (`ac3d.cpp:4919`, `5012`) uses the right order, so the checks and the output disagree.
- Reached by `--flatten`, `--fixAll`, `--combineTexture` and `--fixOverlapping2SidedSurface`, whenever a parent has a `rot` and a child has a `loc` or `rot`. Lights under a rotated parent are misplaced too.
- `03/flatten-order.ac`: kids A and B are the same triangle in the parent frame; after `--flatten` they are written in different places, and re-linting says nothing.
- Fix: `currentMatrix.multiply(thisMatrix)`; one reviewer's patched build passes the flatten, fixAll and combineTexture suites. Add a test with a parent `rot` and a child `loc`.

**4. A concave polygon that isn't exactly flat is fanned into triangles outside it** — `ac3d.cpp:6735`, `6441–6480`, `8752–8774` ✔ — **high** — **fixed**
- `checkSurfacePolygonType` only runs on coplanar polygons, so a concave polygon with any noise never gets `concave` set, and everything that trusts the flag fans it from ref 0.
- The coplanar test itself is fragile: the plane comes from the first three refs that are not quite in a line, so a near-collinear start makes a flat polygon "not coplanar" (`04/coplanar_fp_concave.ac`, with one ref 9e-6 off the plane, inside tolerance; the same file exactly flat is reported "not convex").
- Effects:
  - `--splitPolygon` and `.ac` → `.acc`: `04/concave-noncoplanar.ac` (an L of area 3, one vertex lifted 1 mm) comes out with area 4.
  - **Every plain `-o`**: the cleanup splits a non-coplanar quad along 0–2. `04/dart-quad.ac` (a dart of area 1.5, lifted 1 mm) is written with area 2.5, one triangle covering the notch and wound backwards. No option needed.
  - Re-linting either output reports nothing.
- Fix: use Newell's normal for the plane (as `triangulatePolygon` does), run the convexity test on non-coplanar polygons too (projected on that plane), and triangulate with `triangulatePolygon` wherever a fan is used now.

**5. `.acc` → `.ac` writes the `.acc`-only `shader` line** — `ac3d.cpp:4114–4115`, `convertObjectToAc` (`1131–1141`) ✔
- `05/shader.acc -o x.ac` exits 0; linting `x.ac` gives "invalid token: shader", so acclint rejects its own output. Fix: clear `shaders` in `convertObjectToAc`.

**6. `--merge` copies the other file's format as it is** — `ac3d.cpp:9466–9487` ✔ — **high**
- `.acc` merged into an `.ac`: strips and 6-number vertex lines in the `.ac` (re-lint: "invalid surface type: 14", trailing text).
- `.ac` merged into an `.acc`: objects without normals ("missing normal").
- An `AC3Dc` file merged into `AC3Db`: a `MAT…ENDMAT` block under an `AC3Db` header (9 errors on re-lint).
- Fix: convert the merged objects and materials to the base file's format, or refuse mismatched merges.

**7. `--merge`: a group with geometry keeps its old material index, and the merged world's transform is dropped** — `ac3d.cpp:9474–9498` ✔
- `incrementMaterialIndex` shifts surfaces only on polys. `07/merge_other.ac`: group "b" uses `mat 0` (blue); it is written as a poly with `mat 0`, now the base file's red. Surfaces with no `mat` line likewise become the base file's material 0.
- `07/merge_other_loc.ac`: the merged world's `loc 100 0 0` is dropped, so its geometry moves 100 units.
- Fix: shift `mat` on every object with surfaces, give mat-less surfaces an explicit shifted `mat`, and bake the merged world's transform into its kids.

**8. `--fixRgbTexture` renames the texture, but transparency is still read from the old file** — `ac3d.cpp:8040–8041` vs `10706`, `10747`, `10775` ✔ — **high** — **fixed**
- Only `texture.name` changes; `texture.path` still points at the `.rgba`, which reads as "invalid png header" and so counts as opaque.
- `08/rgbleaf.ac` with `--fixAll`: foliage with an alpha `.png` is put in OPAQUE and made single-sided. The same model naming `leaf.png` directly stays two-sided under TRANSPARENT.
- Fix: re-resolve `texture.path` on rename. Also, "invalid png header" and "guessing texture type" ignore `--quiet` and `-Wno-warnings`.

**9. `--combineTexture` writes any extra top-level object twice, even with `--fixAll`** — `ac3d.cpp:10347–10353`, `10375` ✔ — old #9 is wider than two worlds
- The walk collects from every top-level object but rebuilds only the first, and `--fixMultipleWorlds` doesn't remove a non-world extra object. `09/extraobj.ac` with `--fixAll`: 2 triangles become 3.

**10. `--fixSurface2SidedOpaque` makes translucent-material surfaces single-sided** — `ac3d.cpp:10656`; the check at `6724` has the same blind spot ✔ — found by two reviewers
- Only the texture's alpha is looked at; `isTransparent` elsewhere also counts `trans > 0`. `10/glass-2sided.ac` (material `trans 0.6`, opaque texture, `SURF 0x30`) becomes `0x10`: the glass vanishes from one side.

**11. Crease smoothing in `.ac` → `.acc` depends on surface order** — `ac3d.cpp:1298–1314` ✔
- The crease test compares against the running sum of normals, not the triangle's own normal. `11/crease_{ABC,BCA,CAB}.ac` are the same three triangles in three orders and give 1, 3 and 2 vertices at the origin; only 3 is right.
- Fix: test `own.angleDegrees(other) < crease` with `own` the triangle's face normal.

**12. A version 12 `MAT` block without `ENDMAT` swallows the next `OBJECT`** — `ac3d.cpp:2252–2260` ✔
- Any unknown token ends the block and the line is consumed. With `ENDMAT` missing, `OBJECT world` is lost; "missing ENDMAT" is only reported at end of file. With `-Wno-invalid-token` the world disappears silently.
- One unknown line inside a block (`shine 0`) aborts the block, and the remaining fields are reported as stray tokens and lost.
- Fix: on `OBJECT`/`MAT`/`MATERIAL`, report "missing ENDMAT" and `ungetLine`; on anything else, report and continue.

**13. A missing material field shifts the next field's values into it** — `ac3d.cpp:1902–1911`, `2063–2072` ✔
- `13/mat_missing_shi.ac` (`spec 0 0 0  trans 0.5`) is written `shi 1  trans 0`: 50% transparent becomes opaque. A missing `emis` scrambles `spec` and loses `shi` and `trans` (`13/mat_missing_emis.ac`).
- Not new: the old #15 fix made both flag settings give this same result; before, only the default did.
- Fix: in both catch branches, if the word is the *next* field's keyword, warn "missing <field>", seek back, and return.

**14. A truncated `MATERIAL` line is accepted silently** — `ac3d.cpp:2117–2134` ✔
- `MATERIAL "m" rgb 1 1 1` is written with `amb 0 0 0 … trans 0`, no warning. The version 12 reader does warn. Fix: warn "missing <field>" for each field not reached.

**15. `--splitSURF` / `--splitMat` on a world with its own surfaces writes a second world** — `ac3d.cpp:7895`, `7986` ✔
- `15/world-geom.ac`: output re-lints with "extra OBJECT" and "multiple world"; loaders read only the first world, so the split-off geometry is lost.

**16. A group with geometry and kids slips past both `--fixPolyWithKids` and the cleanup** — `ac3d.cpp:8091`, `7803`, `8298`, `8645–8664` ✔
- `fixPolyWithKids` only looks at polys. `cleanObjects` runs last and retypes a group with vertices to poly, after `cleanSurfaces` (polys only) has already skipped its surfaces.
- `16/group-geom-kids.ac`: `--fixPolyWithKids`, `--splitSURF` and `--grid` all write output that warns "poly with kids"; with `--grid` the group's own surface is in no cell. `16/group-geom-dup.ac`: a plain `-o` leaves its collinear refs and duplicate surface.
- Fix: retype a group with geometry before the other cleaning, and have `fixPolyWithKids` handle it.

**17. `clean()` keeps materials whose last user it removed** — `ac3d.cpp:7799`, `8220` ✔
- `cleanMaterials` runs first and uses `used` flags set at read time. `17/unused-mat-after-clean.ac -o` and `--removeObjects poly drop 17/remove-mat.ac` both write "unused material".
- Fix: recompute `used` from the surfaces left, and run `cleanMaterials` last.

**18. Removing a "collinear" ref that other surfaces use leaves a T-junction** — `ac3d.cpp:8726` (the `TODO: check if shared by other surfaces`) ✔
- `18/tjunction.ac`: the first surface loses vertex 3; the neighbours still use it, now in the middle of an edge. Fix: only drop the ref if no other surface uses the vertex.

**19. `--fixKids` blames an inner group when only the world is short** — `ac3d.cpp:4513–4550` ✔
- `19/root_overcount.ac` (`world kids 4 [a, b, g kids 2 [x, y]]`, a file that stops short): warns that `g` is 1 too many and writes `world [a, b, g[x], y]`, moving `y` out of a correct group. `19/track_root_overcount.ac` moves a `___TKMN1_gl1` out of `TKMN1_g`, breaking the naming rule the track pass enforces.
- The comments at `4200–4205` and `4598–4609` say this case is read as the file describes; the blame loop catches it first because the world alone counts as "starved".
- Fix: when only the root is waiting, treat it as the file stopping short; never move a `___TKMN<n>_gl*` out of `TKMN<n>_g`.

**20. A second `numvert` block in an object is appended, and a triangle is lost** — `ac3d.cpp:2907–3203` ✔
- Refs after the second block index into the first table. `20/two_numvert.ac`: only "unused vertex" ×3 and "duplicate surfaces"; the z=5 triangle is missing from `-o`. Fix: report "multiple numvert", and offset or reject.

## 3. Wrong decisions in checks and fixes

**21. Overlaps between rotated objects are missed** — `ac3d.cpp:7114–7116`, `Triangle::transform` (`ac3d.h:684–693`) ✔
- `transform()` moves the vertices but leaves the normal in object space. `21/overlap_norot.ac`, `overlap_rot60.ac` and `overlap_rot90.ac`: 1, 1 and 0 warnings for the same geometry. Fix: transform the normal too.

**22. Concave polygons are fanned from ref 0 in the overlap and winding checks** — `ac3d.cpp:4934–4957`, `6649–6660` ✔
- `22/overlap_concave_fan.ac`: 2 false "overlapping 2 sided surface", and `--fixOverlapping2SidedSurface` then makes both surfaces single-sided. `22/winding_concave.acc`: false "surface winding". Fix: use `triangulatePolygon` when `concave` is set.

**23. `SameVertex` can take a surface normal from three refs in a line** — `ac3d.cpp:6144–6163` ✔
- The zero normal gives NaN in the angle test at `6215`, which reads as "same". `23/samevertex_collinear_start.ac` merges across a 30° crease; the same file with refs rotated (`23/samevertex_rotated.ac`) doesn't. Fix: skip collinear triples; treat a zero normal as unknown.

**24. `--flatten` scales `.acc` normals with the geometry and never renormalises them** — `ac3d.cpp:9533`, `ac3d.h:512` ✔
- `24/flatten-scale.acc` (`rot` with a scale of 2): normals come out unnormalised and skewed; 3× "invalid normal length" on re-lint. Fix: inverse-transpose and normalise.

**25. Split pieces are appended at the end of the sibling list** — `ac3d.cpp:7895`, `7986` ✔
- `25/splitsurf-order.ac` with `--splitSURF`: `A, B_glass, A-split1`, so half of A is now drawn after the transparent object. Fix: insert each object's pieces right after it.

**26. `--splitMat` does nothing when the first surface has no `mat`** — `ac3d.cpp:7922` ✔
- `26/splitmat-nomat0.ac` stays one object with mat 0 and mat 1. `checkDifferentMat` (`5791`) has the same early return, so nothing warns.

**27. `--fixSurface2SidedOpaque` treats polygons and strips differently** — `ac3d.cpp:10663–10686` R
- A strip wound against its normals is deliberately left 2-sided; a polygon in the same state is made single-sided (`27/opposed-2sided.acc`).

**28. The re-split after the two-sided fixes runs in the wrong cases** — `acclint.cpp:1572` ✔ — needs a decision
- Without `--splitSURF`, `--fixSurface2SidedOpaque` alone still splits `28/mix2s.ac` into `fence` and `fence-split1`; the usage text doesn't say so. Keeping objects from holding a mix is arguably the point, so this may be intended.
- `--fixBackToBackMirror` with `--splitSURF` doesn't re-split, and its output warns "different SURF" (`28/b2b.ac`). That half is a bug.

**29. `--grid` ignores `loc`/`rot`** — `ac3d.cpp:9091–9096`, `9394`, bounds from `8871` ✔
- `29/gridloc.ac`: four objects 500 m apart by `loc` land in one 100 m cell. No harm to the geometry, no culling benefit, and nothing said.

**30. `--grid` can push the tree past the 32-level nesting limit** — `ac3d.cpp:9176–9191`, limit at `2353` ✔
- A cell group is added even when there is only one cell. `30/nest32.ac` (a clean file 31 levels deep) gives output that acclint then refuses to read.

**31. A group or world missing its `kids` line loses its kids to its parent** — `ac3d.cpp:3424–3445` ✔ — the limitation I mentioned with the missing-kids-line fix
- `31/group_missing_kids_line.ac`: the group ends with no kids, is removed as empty, and `b` and `c` are written as top-level objects outside the world, with warnings only. Fix: for a group or world, take the following OBJECTs as its kids.

**32. `numsurf` too high plus a missing `kids` line merges the next object into this one** — `readSurface`, `ac3d.cpp:764–769` R
- `readSurface` returns true on an `OBJECT` line. `--dump poly` shows one poly named `"a" "b"`. An error is reported, so `-o` is blocked. Fix: unget the `OBJECT` line and return false, as for `kids`.

**33. One CR line switches the whole output to CRLF** — `ac3d.cpp:439–443` R
- `m_crlf` is set by any line and never cleared. Fix: take the line ending from the header line, or warn on mixed endings.

**34. Unquoted material-name words that `std::stod` partly parses are fatal** — `ac3d.cpp:1885–1900`, `2046–2061` ✔
- `MATERIAL red information rgb …` ("inf"), `red 2tone`, `red nano` reach the `idx != size` branch: `error()`, nothing written, and `-Wno-invalid-material` can't silence it. `red paint` correctly gives only a warning. Fix: a strict number test, then treat anything else as a word.

**35. The track pass lowers an innocent level group's count** — `ac3d.cpp:4329–4373` R
- `35/track_level_poly_overcount.ac`: the poly `TKMN0` says `kids 1` and takes its sibling; the correct `___TKMN0_gl0 kids 2` is rewritten to 1 instead.

**36. Hitting the 32-level cap prints a false "missing kids" for every ancestor** — `ac3d.cpp:2346–2356`, `3360–3369` R
- `36/deep_complete.ac` (complete, 40 levels): one depth error plus 32 "missing kids: only 1 out of 2". Fix: skip the missing-kids report and `fixKids` once the cap was hit.

## 4. Diagnostics only (low)

**37.** In `37-diagnostics/`:
- **Wrong field named:** "invalid material amb: extra number" for an extra number on `rgb` (`readMaterial` passes the current keyword as `last`, `ac3d.cpp:2117–2126`). `mat_extra_rgb.ac`, `mat_extra_shi.ac`.
- **Note at line 0:** a SURF with no `numsurf` line gives "line 0 note: number specified" showing the header (`3411–3417`). `missing_numsurf.ac`.
- **Two `name` lines:** removal and checks use the first name, the file is written with the last (`4097` vs `getName()`). `two_names.ac`: `--removeObjects poly keep` removes an object whose written name would have been "drop".
- **`checkSurfaceZeroAreaUV` still has the absolute 1.0 floor** that old #11 removed from `collinear()` (`6560`, `6573`; off by default). `zero_uv_floor.ac`.
- **Duplicate surfaces ignore the surface type:** a polygon and a closed line with the same refs are "duplicate", and open lines are compared as loops (`3481–3579`, `5643–5676`). `dupsurf_types2.ac`, `dupsurf_types.acc`. Only the warning is wrong. A strip triangle and a 3-ref line are a "duplicate triangle" (`ac3d.h:944`, `duptri_line.acc`).
- **Three equal refs in a row** are "multiple polygon surface" (`6019–6043`). `triple_ref.ac`.
- **Adjacent refs at one position with different `.acc` normals** are not flagged (`6013–6014`), and the zero-length edge is written. `dup_pos_diff_normal.acc`.
- **Removing a spike tip leaves two equal refs side by side**; the output warns "duplicate surface vertices". `spike.ac`.
- **A poly used as a group also gets "missing surfaces"**, which `-Wno-poly-used-as-group` leaves in place (`5617–5630`). `poly_group_missing.ac`.
- **"2 sided surface with opaque texture (texture: )"** on an untextured surface; the fix never acts on it, so the warning survives the fix. `notex2s.ac`.
- **`--dump` never prints lights,** and in `group` mode a poly's kids print without a parent line (`3682–3724`). `dumplight.ac`.
- **Options silently ignored:** without `-o`, `--merge` (the file isn't even opened), `--grid`, `--fixAll`, `-v` and `--removeObjects` do nothing and exit 0; `--stitchStrips` with `.ac` output is skipped silently. Related to old #41.
- **`-j 2x`** is accepted as 2 (`acclint.cpp:444–446`).

## 5. Performance

**38.** In `38-performance/`:
- **`checkDuplicateVertices` compares every pair of vertices, on by default** (`ac3d.cpp:6251–6269`). `manyverts.ac` (60,000 vertices): 14.6 s.
- **`checkDifferentUV` compares every ref with every other** (`5868–5912`). `grid80.ac` (12,800 triangles): 11.0 s, 7.7 s with `-Wno-different-uv`; the rest is old #43.
- **`convertObjectToAcc` vertex de-duplication** is a linear search per corner (`1440–1461`), so fixing only old #45's smoothing loop would leave the conversion O(T·V). Not timed.

---

## Still open from the last review

8, 14, 16, 19, 20, 23–35, 37–45. Of these, items above widen or overlap old #9 (item 9), #28 (item 37), #41 (item 37) and #43 (item 38). Old #3 is still open for lines and mat-less polygons in `.ac` → `.acc`.

Unverified notes from the reviewers, for the record: `quoted_string operator>>` appends an unset character on an unterminated quote (the caller then fails anyway); the invalid-kids-count recovery continues the parent's loop, so a stray `name`/`numvert` after the recovered kids would attach to the parent; `readMaterial` returns success inverted (every caller ignores it); carets on a BOM file's header line are shifted; a `setjmp`/`longjmp` in the PNG reader skips two destructors (formally UB, clean under valgrind); `m_rename_combine_texture` is never set, so that branch is dead; `getTime` prints 24-hour time with AM/PM.

## Suggested order

1. **#1** — a regression from this round that deletes real geometry on every `-o` at large coordinates. **#2** with it.
2. **#3, #4, #8** — wrong geometry or transparency written by common options; #4 also by a plain `-o`.
3. **#5, #6, #7, #9, #10, #15, #16, #17** — wrong output in specific modes, mostly small fixes.
4. **#11–#14, #20** — parsing.
5. **#19, #31, #35, #36** — the kids-count heuristics, best done together.
6. **#21–#30, #32–#34** — checks and edge cases.
7. **#37, #38** — diagnostics and performance.
