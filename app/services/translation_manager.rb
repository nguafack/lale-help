class TranslationManager
  SUPPORTED_LANGS = I18n.available_locales.map(&:to_sym)

  # FIXME unfortunately this only works for displaying missing keys;
  # it should reject these keys when writing the i18n files, as well.
  IGNORED_KEYS = [
    /\A(active_admin|formtastic|ransack)\./
  ]

  Translation = Struct.new(:key, :languages) do
    def missing_languages
      SUPPORTED_LANGS-languages
    end

    def translate lang
      I18n.t(key, locale: lang.to_sym)
    end
  end


  def clean
    Dir.glob(Rails.root.to_s+'/config/locales/**/*.yml').each do |path|
      log "Removing: #{path}"
      FileUtils.rm_rf path
    end

    save
  end

  def add key, new_translations
    new_translations.each do |lang, val|
      I18n.backend.store_translations(lang.to_sym, deep_hash(key.strip, val), :escape => false)
      puts I18n.t(key, locale: lang.to_sym)
    end

    save
  end

  def remove key
    SUPPORTED_LANGS.each do |lang|
      I18n.backend.store_translations(lang.to_sym, deep_hash(key.strip, nil), :escape => false)
      puts I18n.t(key, locale: lang.to_sym)
    end

    save
  end

  def save
    SUPPORTED_LANGS.each do |lang|
      yaml = { lang => deep_sort(deep_compact(translations_for(lang))) }.to_yaml
      path = Rails.root.to_s+"/config/locales/#{lang}.yml"
      log "Saving: #{path}"
      File.open(path, 'w') { |f| f.puts(yaml) }
    end
  end

  def all_translations
    all_keys = Hash.new

    SUPPORTED_LANGS.each do |lang|
      paths = deep_keys(translations_for(lang)).map{|p| p.join('.') }
      paths.each do |path|
        if I18n.t(path, locale: lang, default: nil).present?
          all_keys[path] ||= []
          all_keys[path] << lang
        end
      end
    end

    all_keys.map { |key, langs| Translation.new(key, langs) }.sort_by(&:key)
  end


  def missing_translations
    all_translations.
      select { |t| t.languages.length != SUPPORTED_LANGS.length && !IGNORED_KEYS.any?{|ignore| t.key =~ ignore } }
  end

  def search method, query
    translations = send(method)
    if query.present?
      query = /#{query}/i
      translations.select do |translation|
        [
          translation.key =~ query,
          SUPPORTED_LANGS.map {|l| translation.translate(l) =~ query }
        ].flatten.any?

      end
    else
      translations
    end
  end


  def translations_for lang
    I18n.backend.send(:translations)[lang]
  end

  private
  def log str
    Rails.logger.info "[TranslationManager] #{str}"
  end


  def deep_hash key, val
    hash = {}
    parts = key.split('.')
    parts.each_with_index.reduce(hash) do |memo, (_key, idx)|
      if idx == parts.length - 1
        memo[_key] = val
      else
        memo[_key] = {}
      end
    end
    hash
  end


  def deep_keys hash, path=[]
    if hash.is_a? Hash
      hash.flat_map do |key, _|
        deep_keys(hash[key], path + [ key ])
      end
    else
      [ path ]
    end
  end

  def deep_compact(hash)
    hash.inject({}) do |new_hash, (k,v)|
      new_val = v.class == Hash ? deep_compact(v) : v
      new_hash[k] = new_val if new_val.class == FalseClass || new_val.present?
      new_hash
    end
  end

  def deep_sort(object)
    return object unless object.is_a?(Hash)
    hash = Hash.new
    object.each { |k, v| hash[k] = deep_sort(v) }
    sorted = hash.sort { |a, b| a[0].to_s <=> b[0].to_s }
    hash.class[sorted]
  end

end
