import { ApiError } from '../../core/ApiError.js';
import { categoryRepository } from './category.repository.js';
import { toCategoryDto } from './category.mapper.js';

export const categoryService = {
  list(filters) {
    return categoryRepository.findAll(filters).map(toCategoryDto);
  },

  getById(id) {
    const category = categoryRepository.findById(id);
    if (!category) throw ApiError.notFound('ไม่พบหมวดหมู่นี้');
    return toCategoryDto(category);
  },

  create(payload) {
    return toCategoryDto(categoryRepository.create(payload));
  },

  update(id, payload) {
    this.getById(id);
    return toCategoryDto(categoryRepository.update(id, payload));
  },

  remove(id) {
    this.getById(id);
    if (categoryRepository.countItems(id) > 0) {
      throw ApiError.conflict('ลบไม่ได้ เพราะยังมีเมนูอยู่ในหมวดหมู่นี้ กรุณาย้ายเมนูออกก่อน');
    }
    categoryRepository.remove(id);
  },
};

export default categoryService;
