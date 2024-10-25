build_output := env_var('HOME') / ".cache" / "prefix"
export PYTHONHOSTPATH := ""

cache:
  -rm output
  mkdir -p {{ build_output }} && ln -sf {{ build_output }} "$PWD/output"

build target: cache
  -just clean-bld {{ target }}
  -just clean-cache {{ target }}
  rattler-build build -r {{target}}/"recipe.yaml" \
  {{ if path_exists(join(target, "variant_config.yaml")) == 'true' { "--variant-config " + join(target, "variant_config.yaml") } else { "" } }} \
  --no-include-recipe \
  --no-build-id --keep-build \
  --experimental \
  -c nvidia/label/cuda-12.4.0 \
  -c nvidia \
  -c pytorch \
  -c conda-forge \

clean-bld name:
  -rm -rf output/bld/rattler-build_{{name}}/
  -rm -rf output/**/{{name}}-*

clean-cache name:
  -micromamba info --json | jq -r '.["package cache"][]' | xargs -I {} find {} -name "{{ name }}*" | xargs -I {} rm -rf {}

build-all: cache
  rattler-build build --recipe-dir . --no-include-recipe

venv package:
  just clean-cache {{ package }}
  micromamba create -c {{ build_output }} -n temp {{ package }} --yes

s3-mirror:
  mc mirror --exclude "bld/*" --exclude "src_cache/*" {{ build_output }} us3-gd/meta-forge/ --disable-multipart --overwrite --remove

s3-mirror-rev:
  mc mirror --exclude "bld/*" --exclude "src_cache/*" us3-gd/meta-forge/ {{ build_output }} --disable-multipart
