import Base.isempty

#= 
# Type definition for a FeatureVector.
# Wrapper around a Dict type.
# Restricted to Any type [key] => [value] of Number type.
=#
 
type FeatureVector{K,V<:Number}
  map::Dict{K,V}
  FeatureVector() = new(Dict{K,V}())
  FeatureVector{K,V}(map::Dict{K,V}) = new(map)
end
FeatureVector() = FeatureVector{Any,Number}()
FeatureVector{K,V}(map::Dict{K,V}) = FeatureVector{K,V}(Base.copy(map))

# copies selected fv, and makes a new one.
function copy{K,V}(fv::FeatureVector{K,V})
  new_fv = FeatureVector{K,V}()

  for key in keys(fv)
    new_fv[key] = fv[key]
  end

  return new_fv
end

# gets value of [key] in a FeatureVector
function getindex(fv::FeatureVector, key)
  if haskey(fv,key)
    return fv.map[key]
  end
  return 0
end

# sets value of [key] in a FeatureVector. Must be subtype of number/dict type
function setindex!(fv::FeatureVector, value, key)
  fv.map[key] = value
end

# check to see if the FeatureVector has key.
function haskey(fv::FeatureVector, key)
  return Base.haskey(fv.map,key)
end

# gets all keys of a FeatureVector
function keys(fv::FeatureVector)
  return Base.keys(fv.map)
end

# gets all values of a FeaturVector
function values(fv::FeatureVector)
  return Base.values(fv.map)
end

# check to see if the FeatureVector is empty.
function isempty(fv::FeatureVector)
  return Base.isempty(fv.map)
end

# finds common type of two FeatureVectors 
function find_common_type(fv1::FeatureVector,fv2::FeatureVector)
  if isempty(fv1) && isempty(fv2)
    commonType = (Any,Number)
  elseif isempty(fv1)
    commonType = typeof(first(fv2.map))
  elseif isempty(fv2)
    commonType = typeof(first(fv1.map))
  else
    fv1_type = typeof(first(fv1.map))
    fv2_type = typeof(first(fv2.map))
    commonType = (promote_type(fv1_type[1],fv2_type[1]),
    promote_type(fv1_type[2],fv2_type[2]))
  end

  return commonType
end

# adds two FeatureVectors together
function +(fv1::FeatureVector, fv2::FeatureVector)
  dict_type = find_common_type(fv1,fv2)
  dict = Dict{dict_type[1],dict_type[2]}(fv1.map)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  
  for key in fv2_keys
    if key in fv1_keys
      dict[key] += fv2[key]
    else
      dict[key] = fv2[key]
    end
  end
  
  return FeatureVector(dict)
end

# subtracts two FeatureVectors
function -(fv1::FeatureVector, fv2::FeatureVector)
  dict_type = find_common_type(fv1,fv2)
  dict = Dict{dict_type[1],dict_type[2]}(fv1.map)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)

  for key in fv2_keys
    if key in fv1_keys
      dict[key] -= fv2[key]
    else
      dict[key] = -fv2[key]
    end
  end

  return FeatureVector(dict)
end

# multiplies a FeatureVector by a scalar
function *(fv::FeatureVector, value)
  if isempty(fv)
    return fv
  end

  fv_keys = keys(fv)
  fv_type = typeof(first(fv.map)[2])
  dict = Dict{typeof(first(fv_keys)), promote_type(fv_type,typeof(value))}()

  for key in fv_keys
    dict[key] = fv[key]*value
  end

  return FeatureVector(dict)
end

# divides a FeatureVector by a scalar
function /(fv::FeatureVector, value)
  if isempty(fv)
    return fv
  end

  fv_keys = keys(fv)
  dict = Dict{typeof(first(fv_keys)), typeof(fv[first(fv_keys)]/value)}()
  
  for key in fv_keys
    dict[key] = fv[key]/value
  end

  return FeatureVector(dict)
end

# rationalizes a FeatureVectors values
function //(fv::FeatureVector, value)
  if isempty(fv)
    return fv
  end

  fv_keys = keys(fv)
  dict = Dict{typeof(first(fv_keys)), Rational}()
  for key in fv_keys
    dict[key] = fv[key]//value
  end

  return FeatureVector(dict)
end

# finds the cosine between two vectors and returns 1-cos
function cos_dist(fv1::FeatureVector, fv2::FeatureVector)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  fv1_magnitude = 0
  fv2_magnitude = 0
  dot_product = 0

  for key in fv1_keys
    fv1_value = fv1[key]
    fv1_magnitude += fv1_value*fv1_value
    dot_product += fv1_value*fv2[key]
  end

  for key in fv2_keys
    fv2_value = fv2[key]
    fv2_magnitude += fv2_value*fv2_value
  end

  cosine = dot_product/(sqrt(fv1_magnitude)*sqrt(fv2_magnitude))
  if cosine > 1 - 1e-15
    cosine = 1
  end

  return 1 - cosine
end

# number of disjoint nonzero dimensions between vectors
function zero_dist(fv1::FeatureVector, fv2::FeatureVector)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  distance = 0

  for key in fv1_keys
    if fv1[key] != 0 && fv2[key] == 0
      distance += 1
    end
  end

  for key in fv2_keys
    if fv2[key] != 0 && fv1[key] == 0
      distance += 1
    end
  end

  return distance
end

# sum of absolute distance between dimensions
function taxicab_dist(fv1::FeatureVector, fv2::FeatureVector)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  distance = 0

  for key in fv1_keys
    distance += abs(fv1[key]-fv2[key])
  end

  for key in fv2_keys
    if !haskey(fv1, key)
      distance += abs(fv2[key])
    end
  end

  return distance
end

# ordinary distance between vectors
function euclidean_dist(fv1::FeatureVector, fv2::FeatureVector)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  distance = 0

  for key in fv1_keys
    distance += (fv1[key]-fv2[key])^2
  end

  for key in fv2_keys
    if !haskey(fv1, key)
      distance += fv2[key]^2
    end
  end

  return sqrt(distance)
end

# maximum absolute difference between dimensions
function infinite_dist(fv1::FeatureVector, fv2::FeatureVector)
  fv1_keys = keys(fv1)
  fv2_keys = keys(fv2)
  max = 0

  for key in fv1_keys
    current = abs(fv1[key]-fv2[key])
    if current > max
      max = current
    end
  end

  for key in fv2_keys
    current = 0
    if !haskey(fv1, key)
      current = abs(fv2[key])
    end
    if current > max
      max = current
    end
  end

  return max
end