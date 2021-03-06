// ======================================================================== //
// Copyright 2009-2013 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include "image.isph"

struct Image3fa
{
  Image base;
  vec3fa* data;
};

inline uniform vec3f Image3fa__get_nearest_uniform(const uniform Image *uniform _this, const uniform int x, const uniform int y) 
{
  const uniform Image3fa *uniform this = (const uniform Image3fa *uniform)_this;
  return make_vec3f(this->data[x+this->base.size.x*y]);
}

inline varying vec3f Image3fa__get_nearest_varying(const uniform Image *uniform _this, const varying int x, const varying int y) 
{
  const uniform Image3fa *uniform this = (const uniform Image3fa *uniform)_this;
  const varying int idx = x+this->base.size.x*y;
  return make_vec3f(this->data[idx]);
}

varying vec3f Image3fa__get_bilinear_varying(const uniform Image *uniform _this, const varying float x, const varying float y) 
{ 
  const uniform Image3fa *uniform this = (const uniform Image3fa *uniform)_this;

  /* repeat texture */
  const float xr = (x-floor(x))*(float)this->base.size.x;
  const float yr = (y-floor(y))*(float)this->base.size.y;

  /* calculate interpolation weights */
  const float sx = xr-floor(xr);
  const float sy = yr-floor(yr);

  /* read texels */
  const int x0 = clamp((int)xr,0,this->base.size.x-1);
  const int y0 = clamp((int)yr,0,this->base.size.y-1);
  const int x1 = x0+1 == this->base.size.x ? 0 : x0+1;
  const int y1 = y0+1 == this->base.size.y ? 0 : y0+1;

  const vec3f c00 = Image3fa__get_nearest_varying(_this,x0,y0);
  const vec3f c01 = Image3fa__get_nearest_varying(_this,x0,y1);
  const vec3f c10 = Image3fa__get_nearest_varying(_this,x1,y0);
  const vec3f c11 = Image3fa__get_nearest_varying(_this,x1,y1);
  
  /* interpolate texels */
  return lerp(sy,
              lerp(sx,c00,c10),
              lerp(sx,c01,c11));
}

void Image3fa__Destructor(uniform RefCount* uniform _this)
{
  uniform Image3fa* uniform this = (uniform Image3fa* uniform) _this;
  delete[] this->data;
  Image__Destructor(_this);
}

void Image3fa__Constructor(uniform Image3fa* uniform this, const uniform vec2ui size, uniform vec3fa* uniform data)
{
  Image__Constructor(&this->base,
                     Image3fa__Destructor,size,
                     Image3fa__get_nearest_uniform,
                     Image3fa__get_nearest_varying,
                     Image3fa__get_bilinear_varying);
  this->data = data;
}

export void* uniform Image3fa__new(const uniform int size_x, const uniform int size_y, uniform vec3fa* uniform data, const uniform bool copy)
{
  uniform Image3fa *uniform this = uniform new uniform Image3fa;
  if (copy) {
    uniform vec3fa* uniform local = uniform new uniform vec3fa[size_x*size_y];
    memcpy(local,data,size_x*size_y*sizeof(uniform vec3fa));
    Image3fa__Constructor(this,make_vec2ui(size_x,size_y),local);
  } else {
    Image3fa__Constructor(this,make_vec2ui(size_x,size_y),data);
  }
  return this;
}
