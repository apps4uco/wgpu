using namespace metal;

struct OutVertex {
    float4 Position [[position]];
    float4 Color [[user(locn0)]];
};

struct OutPrimitive {
    float4 ColorMask [[flat]] [[user(locn1)]];
    bool CullPrimitive [[primitive_culled]];
};

struct InVertex {
};

struct InPrimitive {
    float4 ColorMask [[flat]] [[user(locn1)]];
};

struct FragmentIn {
    float4 Color [[user(locn0)]];
    float4 ColorMask [[flat]] [[user(locn1)]];
};

struct PayloadData {
    float4 ColorMask;
    bool Visible;
};

using Meshlet = metal::mesh<OutVertex, OutPrimitive, 3, 1, topology::triangle>;


constant float4 positions[3] = {
    float4(0.0, 1.0, 0.0, 1.0),
    float4(-1.0, -1.0, 0.0, 1.0),
    float4(1.0, -1.0, 0.0, 1.0)
};

constant float4 colors[3] = {
    float4(0.0, 1.0, 0.0, 1.0),
    float4(0.0, 0.0, 1.0, 1.0),
    float4(1.0, 0.0, 0.0, 1.0)
};


[[object]]
void taskShader(uint3 tid [[thread_position_in_grid]], object_data PayloadData &outPayload [[payload]], mesh_grid_properties grid) {
    outPayload.ColorMask = float4(1.0, 1.0, 0.0, 1.0);
    outPayload.Visible = true;
    grid.set_threadgroups_per_grid(uint3(3, 1, 1));
}

[[mesh]]
[[max_total_threads_per_threadgroup(32)]]
void meshShader(
    object_data PayloadData const& payload [[payload]],
    uint thread_id [[thread_position_in_threadgroup]],
    uint local_id [[thread_index_in_threadgroup]],
    Meshlet out
)
{
  if (thread_id==0) {
    out.set_primitive_count(1);
  }

  uint i=thread_id;
  if (i<3) {
        OutVertex vert;
        vert.Position = positions[i];
        vert.Color = colors[i] * payload.ColorMask;
        out.set_vertex(i, vert);
        out.set_index(i, i);
    }

  if (thread_id==0) {
    OutPrimitive prim;
    prim.ColorMask = float4(1.0, 0.0, 0.0, 1.0);
    prim.CullPrimitive = !payload.Visible;
    out.set_primitive(0, prim);
  }
}

fragment float4 fragShader(FragmentIn data [[stage_in]]) {
    return data.Color * data.ColorMask;
}
