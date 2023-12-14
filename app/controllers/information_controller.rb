class InformationController < ApplicationController
  def information
    trust_items = TrustItem.all
    items = Item.all
    @all_items = trust_items + items

    # Most Prolific Author
    author_counts = @all_items.reject { |item| item.author.blank? }.group_by(&:author).transform_values(&:count)
    sorted_authors = author_counts.sort_by { |_, count| count }.reverse

    # Find the most prolific author or use the second most prolific
    @most_prolific_author = sorted_authors[0]&.first || sorted_authors[1]&.first

    if @most_prolific_author.present? && Source.exists?(["LOWER(name) = ?", @most_prolific_author.downcase])
      next_index = sorted_authors.index { |author, _| author.downcase != @most_prolific_author.downcase }

      # Find the next people name or initialize to nil if none is found
      @most_prolific_author = find_next_people_name(sorted_authors, next_index)

      @most_prolific_author_source = TrustItem.where(author: @most_prolific_author).pluck(:source)
    end

    # Most Prolific Source
    source_counts = @all_items.group_by(&:source).transform_values(&:count)
    sorted_sources = source_counts.sort_by { |_, count| count }.reverse

    # Find the most prolific source or use the second most prolific
    @most_prolific_source = sorted_sources[0]&.first || sorted_sources[1]&.first

    # Classification Counts
    classification_counts = @all_items.group_by(&:classification).transform_values(&:count)
    @true_count = classification_counts['true'].to_i
    @fake_count = classification_counts['false'].to_i
    @classification_counts = classification_counts['Clickbait'].to_i

    # Top 5 Authors (excluding empty names and non-names)
    @top_authors = sorted_authors.select { |author, _| is_valid_name_or_initials?(author) }.first(7).to_h

    # Top 5 Sources
    @top_sources = sorted_sources.first(7).to_h

    @author_names = @top_authors.keys
    @author_values = @top_authors.values

    @source_names = @top_sources.keys
    @source_values = @top_sources.values

    # Assuming you have a TrustItem model and a variable named @the_most_clickbait_source

    # Find the most clickbait source
    most_clickbait_source = TrustItem.where(classification: 'Clickbait')
                                     .group(:source)
                                     .order('count_source DESC')
                                     .limit(1)
                                     .count(:source)
                                     .keys
                                     .first

    # Assign the result to the variable
    @the_most_clickbait_source = most_clickbait_source


    @fastest_source = FastestSource.group(:source).count.max_by { |_, count| count }&.first
  end

  private

  def is_valid_name_or_initials?(name)
    name.match?(/^[A-Z][a-z]+ [A-Z][a-z]+$/) || name.match?(/^[A-Z]\.[A-Z]\.?$/) # Full name or initials
  end

  def find_next_people_name(authors, start_index)
    return nil if start_index.nil?

    (start_index...authors.size).each do |index|
      author, _ = authors[index]
      return author if is_valid_name_or_initials?(author)
    end

    nil
  end
end
