# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/choice_field'

describe HexaPDF::Type::AcroForm::ChoiceField do
  before do
    @doc = HexaPDF::Document.new
    @field = @doc.add({FT: :Ch, T: 'choice'}, type: :XXAcroFormField, subtype: :Ch)
  end

  it "can be initialized as list box" do
    @field.initialize_as_list_box
    assert_nil(@field[:V])
    assert(@field.list_box?)
  end

  it "can be initialized as combo box" do
    @field.initialize_as_combo_box
    assert_nil(@field[:V])
    assert(@field.combo_box?)
  end

  describe "field_value" do
    it "returns the correct Unicode string value" do
      @field[:V] = "H\xe4llo".b
      assert_equal("Hällo", @field.field_value)
    end

    it "returns an array of Unicode string values" do
      @field[:V] = ["H\xe4llo".b, "\xFE\xFF".b << "Óthér".encode('UTF-16BE').b]
      assert_equal(["Hällo", "Óthér"], @field.field_value)
    end
  end

  describe "field_value=" do
    before do
      @field.option_items = ["test", "other"]
    end

    describe "combo_box" do
      before do
        @field.initialize_as_combo_box
      end

      it "can set the value for an uneditable combo box" do
        @field.field_value = 'test'
        assert_equal("test", @field[:V])
      end

      it "can set the value for an editable combo box" do
        @field.flag(:edit)
        @field.field_value = 'another'
        assert_equal("another", @field[:V])
      end

      it "fails if mulitple values are provided for a combo box" do
        assert_raises(HexaPDF::Error) { @field.field_value = ['a', 'b'] }
      end

      it "fails if an unlisted value is specified for an uneditable combo box" do
        assert_raises(HexaPDF::Error) { @field.field_value = 'a' }
      end
    end

    describe "list_box" do
      before do
        @field.initialize_as_list_box
      end

      it "can set a single value" do
        @field.field_value = 'test'
        assert_equal("test", @field[:V])
      end

      it "can set a multiple values if the list box is a multi-select" do
        @field.flag(:multi_select)
        @field.field_value = ['test', 'other']
        assert_equal(['test', 'other'], @field[:V].value)
      end

      it "fails if mulitple values are provided but the list box is not a multi-select" do
        assert_raises(HexaPDF::Error) { @field.field_value = ['a', 'b'] }
      end

      it "fails if an unlisted value is specified" do
        assert_raises(HexaPDF::Error) { @field.field_value = 'a' }
      end
    end
  end

  it "sets and returns the default field value" do
    @field.option_items = ["hällo"]
    @field.default_field_value = 'hällo'
    assert_equal('hällo', @field.default_field_value)
    assert_raises(HexaPDF::Error) { @field.default_field_value = 'unknown' }
  end

  it "sets and returns the array with the option items" do
    assert_equal([], @field.option_items)
    @field.option_items = ["H\xe4llo".b, "\xFE\xFF".b << "Töne".encode('UTF-16BE').b]
    assert_equal(["Hällo", "Töne"], @field.option_items)
  end

  it "returns the correct concrete field type" do
    assert_equal(:list_box, @field.concrete_field_type)
    @field.initialize_as_combo_box
    assert_equal(:combo_box, @field.concrete_field_type)
  end

  describe "create_appearances" do
    before do
      @widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
    end

    it "works for combo box fields" do
      @field.initialize_as_combo_box
      @field.set_default_appearance_string
      @field.create_appearances
      assert(@field[:AP][:N])
    end

    it "fails for list boxes" do
      assert_raises(HexaPDF::Error) { @field.create_appearances }
    end
  end

  describe "validation" do
    it "checks the value of the /FT field" do
      @field.delete(:FT)
      refute(@field.validate(auto_correct: false))
      assert(@field.validate)
      assert_equal(:Ch, @field.field_type)
    end
  end
end
