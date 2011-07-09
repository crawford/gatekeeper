def keys_to_symbols(value)
	return value if not value.is_a?(Hash)
	hash = value.inject({}) do |hash,(k,v)|
		hash[k.to_sym] = keys_to_symbols(v)
		hash
	end
end

def add_to_loadpath(*paths)
	curdir = Dir.pwd
	paths.each do |path|
		$LOAD_PATH.unshift("#{curdir}/#{path}")
	end
end

