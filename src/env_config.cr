require "./env_config/*"

module EnvConfig
  annotation Setting
  end

  def initialize(env : ENV.class, prefix = nil)
    {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for var in @type.instance_vars %}
        {% ann = var.annotation(::EnvConfig::Setting) %}
        {% unless ann && ann[:ignore] %}
          {%
            properties[var.id] = {
              key: (ann && ann[:key] || var.id.stringify).upcase,
              type: var.type,
              has_default: var.has_default_value?,
              default: var.default_value,
              nilable: var.type.nilable?,
              converter: ann && ann[:converter]
            }
          %}
        {% end %}
      {% end %}

      {% for name, options in properties %}
        %key{name} = [prefix.try(&.upcase), {{ options[:key] }}].compact.join('_')
        %found{name} = {{ options[:type] < ::EnvConfig }} || ENV.has_key?(%key{name})
        %var{name} =
          {% if options[:type] < ::EnvConfig %}
            {{ options[:type] }}.new(env, prefix: %key{name})
          {% elsif options[:nilable] || options[:has_default] || options[:type] == Bool %}
            ENV[%key{name}]?.try do |value|
          {% else %}
            ENV[%key{name}].try do |value|
          {% end %}

          {% unless options[:type] < ::EnvConfig %}
            {% if options[:converter] %}
              {{ options[:converter] }}.from_env(value)
            {% elsif options[:nilable] || options[:type] == String %}
              value
            {% elsif options[:type] == Bool %}
              value !~ /^false$/i && value != "0"
            {% else %}
              ::Union({{ options[:type] }}).new(value)
            {% end %}
            end
          {% end %}

        {% if options[:nilable] %}
          {% if options[:has_default] != nil %}
            @{{name}} = %found{name} ? %var{name} : {{options[:default]}}
          {% else %}
            @{{name}} = %var{name}
          {% end %}
        {% elsif options[:has_default] %}
          @{{name}} = %var{name}.nil? ? {{options[:default]}} : %var{name}
        {% elsif options[:type] == Bool %}
          @{{name}} = %found{name} && !!%var{name}
        {% else %}
          @{{name}} = (%var{name}).as({{options[:type]}})
        {% end %}
      {% end %}
    {% end %}
  end
end
